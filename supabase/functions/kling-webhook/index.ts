// Kling webhook receiver. KLING_WEBHOOK_SECRET is a function secret, never a
// Flutter dart-define. Verifies X-Kling-Signature over the raw body.
// Test-mode events only. ISK integers as-is (never x100).
// Fulfilment is idempotent on event id and payment_intent id.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { verifyKlingSignature } from "../_shared/kling_signature.ts";
import {
  decideKlingWebhookEvent,
  parseKlingEvent,
  type JsonMap,
  type KlingSubscriptionPatch,
} from "../_shared/kling_webhook.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-kling-signature, x-kling-event, x-kling-delivery-id",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function serviceClient() {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function patchToRow(patch: KlingSubscriptionPatch): JsonMap {
  const row: JsonMap = {
    id: patch.subscriptionId,
    last_event_id: patch.eventId,
    last_event_type: patch.eventType,
    updated_at: new Date().toISOString(),
  };
  if (patch.status != null) row.status = patch.status;
  if (patch.paid != null) row.paid = patch.paid;
  if (patch.accessRevoked != null) row.access_revoked = patch.accessRevoked;
  if (patch.cancelAtPeriodEnd != null) {
    row.cancel_at_period_end = patch.cancelAtPeriodEnd;
  }
  if (patch.amountIsk != null) row.amount_isk = patch.amountIsk;
  if (patch.currency != null) row.currency = patch.currency;
  if (patch.periodStart != null) row.period_start = patch.periodStart;
  if (patch.periodEnd != null) row.period_end = patch.periodEnd;
  if (patch.paymentIntentId != null) {
    row.last_payment_intent_id = patch.paymentIntentId;
  }
  if (patch.companyId != null) row.company_id = patch.companyId;
  return row;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const secret = Deno.env.get("KLING_WEBHOOK_SECRET") ?? "";

  if (req.method === "GET") {
    return jsonResponse({ configured: Boolean(secret) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!secret) {
    return jsonResponse(
      { error: "KLING_WEBHOOK_SECRET is not configured on this function" },
      500,
    );
  }

  const rawBody = await req.text();
  const header = req.headers.get("x-kling-signature");
  const valid = await verifyKlingSignature(rawBody, header, secret);
  if (!valid) {
    return jsonResponse({ error: "Invalid signature" }, 401);
  }

  let parsedJson: unknown;
  try {
    parsedJson = JSON.parse(rawBody);
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const parsed = parseKlingEvent(parsedJson);
  if ("error" in parsed) {
    return jsonResponse({ error: parsed.error }, 400);
  }
  const { event } = parsed;

  const headerType = req.headers.get("x-kling-event");
  if (headerType && headerType !== event.type) {
    return jsonResponse({ error: "X-Kling-Event does not match body type" }, 400);
  }

  const supabase = serviceClient();
  if (!supabase) {
    return jsonResponse(
      { error: "SUPABASE_URL is not configured on this function" },
      500,
    );
  }

  const { data: existingEvent, error: existingEventError } = await supabase
    .from("kling_webhook_events")
    .select("id, processed")
    .eq("id", event.id)
    .maybeSingle();
  if (existingEventError) {
    return jsonResponse({ error: "Failed to read webhook events" }, 500);
  }

  let alreadyCaptured = false;
  const subscriptionHint =
    typeof event.data.subscription_id === "string"
      ? event.data.subscription_id
      : typeof event.data.subscriptionId === "string"
      ? event.data.subscriptionId
      : typeof event.data.id === "string" && event.type.startsWith("subscription.")
      ? event.data.id
      : undefined;
  const paymentIntentHint =
    event.type === "payment_intent.captured" &&
      typeof event.data.id === "string"
      ? event.data.id
      : typeof event.data.payment_intent_id === "string"
      ? event.data.payment_intent_id
      : typeof event.data.paymentIntentId === "string"
      ? event.data.paymentIntentId
      : undefined;

  if (subscriptionHint && paymentIntentHint) {
    const { data: existingSub } = await supabase
      .from("kling_subscriptions")
      .select("last_payment_intent_id")
      .eq("id", subscriptionHint)
      .maybeSingle();
    alreadyCaptured =
      existingSub?.last_payment_intent_id === paymentIntentHint;
  }

  const decision = decideKlingWebhookEvent({
    event,
    alreadyProcessedEventId: Boolean(existingEvent?.processed),
    alreadyCapturedPaymentIntentId: alreadyCaptured,
  });

  const deliveryId = req.headers.get("x-kling-delivery-id");
  const eventRow = {
    id: event.id,
    type: event.type,
    environment: event.environment ?? "test",
    delivery_id: deliveryId,
    payload: parsedJson,
    processed: true,
    processed_at: new Date().toISOString(),
  };

  if (existingEvent?.processed) {
    return jsonResponse({ duplicate: true, reason: "event_id" });
  }

  if (decision.kind === "duplicate") {
    const { error: insertDupError } = await supabase
      .from("kling_webhook_events")
      .upsert(eventRow, { onConflict: "id" });
    if (insertDupError) {
      return jsonResponse({ error: "Failed to record webhook event" }, 500);
    }
    return jsonResponse({ duplicate: true, reason: decision.reason });
  }

  if (decision.kind === "ignore") {
    const { error: insertIgnoreError } = await supabase
      .from("kling_webhook_events")
      .upsert(eventRow, { onConflict: "id" });
    if (insertIgnoreError) {
      return jsonResponse({ error: "Failed to record webhook event" }, 500);
    }
    return jsonResponse({ ignored: true, reason: decision.reason });
  }

  const row = patchToRow(decision.patch);
  const { error: upsertError } = await supabase
    .from("kling_subscriptions")
    .upsert(row, { onConflict: "id" });
  if (upsertError) {
    return jsonResponse({ error: "Failed to apply subscription state" }, 500);
  }

  const { error: insertError } = await supabase
    .from("kling_webhook_events")
    .upsert(eventRow, { onConflict: "id" });
  if (insertError) {
    return jsonResponse({ error: "Failed to record webhook event" }, 500);
  }

  return jsonResponse({
    ok: true,
    event_id: event.id,
    type: event.type,
    subscription_id: decision.patch.subscriptionId,
    access_revoked: decision.patch.accessRevoked ?? false,
    paid: decision.patch.paid ?? null,
  });
});
