// Secret-key Stripe proxy. STRIPE_SECRET_KEY is a function secret, never a
// client dart-define. Allowlisted actions only — no arbitrary Stripe paths.
// Callers must present a valid Supabase Auth user JWT (verify_jwt=true).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

const STRIPE_API = "https://api.stripe.com/v1";
const MAX_AMOUNT_DOLLARS = 10_000;
const MIN_CENTS = 50;
const ALLOWED_CURRENCIES = new Set(["usd"]);
const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 20;
const MAX_STRING = 500;
const STRIPE_ID = /^[a-zA-Z0-9_]{1,255}$/;

type JsonMap = Record<string, unknown>;

const rateBuckets = new Map<string, number[]>();

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function asString(value: unknown, max = MAX_STRING): string | undefined {
  if (typeof value === "string" && value.trim().length > 0) {
    const trimmed = value.trim();
    if (trimmed.length > max) return undefined;
    return trimmed;
  }
  return undefined;
}

function asNumber(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return undefined;
}

function looksLikeEmail(value: string): boolean {
  return value.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function looksLikeStripeId(value: string, prefix: string): boolean {
  return value.startsWith(prefix) && STRIPE_ID.test(value);
}

function isRateLimited(userId: string): boolean {
  const now = Date.now();
  const recent = (rateBuckets.get(userId) ?? []).filter(
    (stamp) => now - stamp < RATE_LIMIT_WINDOW_MS,
  );
  if (recent.length >= RATE_LIMIT_MAX) {
    rateBuckets.set(userId, recent);
    return true;
  }
  recent.push(now);
  rateBuckets.set(userId, recent);
  return false;
}

async function requireUser(
  req: Request,
): Promise<{ userId: string } | Response> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length).trim()
    : "";
  if (!token) {
    return jsonResponse({ error: "Missing Authorization bearer token" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );

  const { data, error } = await supabase.auth.getUser(token);
  const user = data.user;
  if (error || !user || user.is_anonymous) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }
  if (isRateLimited(user.id)) {
    return jsonResponse({ error: "Too many requests" }, 429);
  }
  return { userId: user.id };
}

async function stripeRequest(
  secret: string,
  path: string,
  method: string,
  params?: Record<string, string>,
): Promise<{ ok: boolean; status: number; body: JsonMap }> {
  const url = new URL(`${STRIPE_API}${path}`);
  const headers: Record<string, string> = {
    Authorization: `Bearer ${secret}`,
  };

  let body: string | undefined;
  if (method === "GET") {
    if (params) {
      for (const [key, value] of Object.entries(params)) {
        url.searchParams.set(key, value);
      }
    }
  } else if (params) {
    headers["Content-Type"] = "application/x-www-form-urlencoded";
    body = new URLSearchParams(params).toString();
  }

  const response = await fetch(url, { method, headers, body });
  const parsed = await response.json();
  const jsonBody = parsed && typeof parsed === "object"
    ? parsed as JsonMap
    : { error: "Unexpected Stripe response" };
  return { ok: response.ok, status: response.status, body: jsonBody };
}

function stripeErrorStatus(result: { status: number }): number {
  return result.status >= 400 && result.status < 600 ? result.status : 502;
}

async function handleAction(
  secret: string,
  action: string,
  payload: JsonMap,
  userId: string,
): Promise<Response> {
  switch (action) {
    case "createPaymentIntent": {
      const amount = asNumber(payload.amount);
      const currency = asString(payload.currency, 8)?.toLowerCase();
      const description = asString(payload.description);
      const companyId = asString(payload.companyId, 128);
      if (amount == null || !currency) {
        return jsonResponse(
          { error: "amount and currency are required" },
          400,
        );
      }
      if (!ALLOWED_CURRENCIES.has(currency)) {
        return jsonResponse({ error: "currency is not supported" }, 400);
      }
      if (amount <= 0 || amount > MAX_AMOUNT_DOLLARS) {
        return jsonResponse({ error: "amount is out of range" }, 400);
      }
      const cents = Math.round(amount * 100);
      if (cents < MIN_CENTS) {
        return jsonResponse({ error: "amount is too small" }, 400);
      }
      const params: Record<string, string> = {
        amount: String(cents),
        currency,
        "automatic_payment_methods[enabled]": "true",
        "metadata[auth_user_id]": userId,
      };
      if (description) params.description = description;
      if (companyId) params["metadata[company_id]"] = companyId;
      params["metadata[subscription_type]"] = "monthly";
      const result = await stripeRequest(
        secret,
        "/payment_intents",
        "POST",
        params,
      );
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "createCustomer": {
      const email = asString(payload.email, 254);
      const name = asString(payload.name, 200);
      const phone = asString(payload.phone, 40);
      if (!email || !name || !looksLikeEmail(email)) {
        return jsonResponse({ error: "email and name are required" }, 400);
      }
      const params: Record<string, string> = { email, name };
      if (phone) params.phone = phone;
      params["metadata[auth_user_id]"] = userId;
      const result = await stripeRequest(secret, "/customers", "POST", params);
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "createSubscription": {
      const customerId = asString(payload.customerId, 255);
      const priceId = asString(payload.priceId, 255);
      const paymentMethodId = asString(payload.paymentMethodId, 255);
      if (
        !customerId || !priceId || !paymentMethodId ||
        !looksLikeStripeId(customerId, "cus_") ||
        !looksLikeStripeId(priceId, "price_") ||
        !looksLikeStripeId(paymentMethodId, "pm_")
      ) {
        return jsonResponse(
          { error: "customerId, priceId, and paymentMethodId are required" },
          400,
        );
      }
      const result = await stripeRequest(secret, "/subscriptions", "POST", {
        customer: customerId,
        "items[0][price]": priceId,
        default_payment_method: paymentMethodId,
        "expand[]": "latest_invoice.payment_intent",
        "metadata[auth_user_id]": userId,
      });
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "getPaymentMethods": {
      const customerId = asString(payload.customerId, 255);
      if (!customerId || !looksLikeStripeId(customerId, "cus_")) {
        return jsonResponse({ error: "customerId is required" }, 400);
      }
      const result = await stripeRequest(secret, "/payment_methods", "GET", {
        customer: customerId,
        type: "card",
      });
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "cancelSubscription": {
      const subscriptionId = asString(payload.subscriptionId, 255);
      if (!subscriptionId || !looksLikeStripeId(subscriptionId, "sub_")) {
        return jsonResponse({ error: "subscriptionId is required" }, 400);
      }
      const result = await stripeRequest(
        secret,
        `/subscriptions/${encodeURIComponent(subscriptionId)}`,
        "DELETE",
      );
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    default:
      return jsonResponse({ error: `Unknown action: ${action}` }, 400);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const userOrError = await requireUser(req);
  if (userOrError instanceof Response) {
    return userOrError;
  }

  const secret = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

  if (req.method === "GET") {
    return jsonResponse({ configured: Boolean(secret) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!secret) {
    return jsonResponse(
      { error: "STRIPE_SECRET_KEY is not configured on this function" },
      500,
    );
  }

  try {
    const body = await req.json() as JsonMap;
    const action = asString(body.action, 64);
    const payload = body.payload && typeof body.payload === "object"
      ? body.payload as JsonMap
      : {};
    if (!action) {
      return jsonResponse({ error: "action is required" }, 400);
    }
    return await handleAction(secret, action, payload, userOrError.userId);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Request failed";
    return jsonResponse({ error: message }, 400);
  }
});
