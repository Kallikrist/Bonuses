// Secret-key Stripe proxy. STRIPE_SECRET_KEY is a function secret, never a
// client dart-define. Allowlisted actions only — no arbitrary Stripe paths.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

const STRIPE_API = "https://api.stripe.com/v1";

type JsonMap = Record<string, unknown>;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function asString(value: unknown): string | undefined {
  if (typeof value === "string" && value.trim().length > 0) {
    return value.trim();
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
): Promise<Response> {
  switch (action) {
    case "createPaymentIntent": {
      const amount = asNumber(payload.amount);
      const currency = asString(payload.currency)?.toLowerCase();
      const description = asString(payload.description);
      const companyId = asString(payload.companyId);
      if (amount == null || amount <= 0 || !currency) {
        return jsonResponse(
          { error: "amount and currency are required" },
          400,
        );
      }
      const cents = Math.round(amount * 100);
      if (cents < 1) {
        return jsonResponse({ error: "amount is too small" }, 400);
      }
      const params: Record<string, string> = {
        amount: String(cents),
        currency,
        "automatic_payment_methods[enabled]": "true",
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
      const email = asString(payload.email);
      const name = asString(payload.name);
      const phone = asString(payload.phone);
      if (!email || !name) {
        return jsonResponse({ error: "email and name are required" }, 400);
      }
      const params: Record<string, string> = { email, name };
      if (phone) params.phone = phone;
      const result = await stripeRequest(secret, "/customers", "POST", params);
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "createSubscription": {
      const customerId = asString(payload.customerId);
      const priceId = asString(payload.priceId);
      const paymentMethodId = asString(payload.paymentMethodId);
      if (!customerId || !priceId || !paymentMethodId) {
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
      });
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "getPaymentMethods": {
      const customerId = asString(payload.customerId);
      if (!customerId) {
        return jsonResponse({ error: "customerId is required" }, 400);
      }
      const result = await stripeRequest(secret, "/payment_methods", "GET", {
        customer: customerId,
        type: "card",
      });
      return jsonResponse(result.body, result.ok ? 200 : stripeErrorStatus(result));
    }
    case "cancelSubscription": {
      const subscriptionId = asString(payload.subscriptionId);
      if (!subscriptionId) {
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
    const action = asString(body.action);
    const payload = body.payload && typeof body.payload === "object"
      ? body.payload as JsonMap
      : {};
    if (!action) {
      return jsonResponse({ error: "action is required" }, 400);
    }
    return await handleAction(secret, action, payload);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Request failed";
    return jsonResponse({ error: message }, 400);
  }
});
