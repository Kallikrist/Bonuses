// Secret-key Kling proxy (second provider alongside Stripe).
// KLING_SECRET_KEY is a function secret, never a Flutter dart-define.
// Allowlisted Path A actions only — no arbitrary Kling paths.
// Test-mode API only. Card only. ISK is zero-decimal: pass integers as-is.
// Never multiply by 100. Webhook handler is BON-41. Flutter client is BON-42.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

const KLING_API = "https://api.kling.is/v1";
const CARD_ONLY = "card";
const ISK = "ISK";
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

function asBoolean(value: unknown): boolean | undefined {
  if (typeof value === "boolean") return value;
  return undefined;
}

function asInteger(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }
  if (typeof value === "string" && /^-?\d+$/.test(value.trim())) {
    const parsed = Number(value.trim());
    if (Number.isInteger(parsed)) return parsed;
  }
  return undefined;
}

function asUuid(value: unknown, field: string): string | Response {
  const text = asString(value);
  if (!text) {
    return jsonResponse({ error: `${field} is required` }, 400);
  }
  if (!UUID_RE.test(text)) {
    return jsonResponse({ error: `${field} must be a UUID` }, 400);
  }
  return text;
}

function isTestSecret(secret: string): boolean {
  return secret.startsWith("sk_test_");
}

function isLiveSecret(secret: string): boolean {
  return secret.startsWith("sk_live_");
}

function stringMetadata(value: unknown): Record<string, string> | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  const out: Record<string, string> = {};
  for (const [key, entry] of Object.entries(value as JsonMap)) {
    if (typeof key !== "string" || key.trim().length === 0) continue;
    if (typeof entry === "string") {
      out[key] = entry;
    } else if (typeof entry === "number" && Number.isFinite(entry)) {
      // ISK and other numeric metadata stay as decimal-string integers, never x100.
      out[key] = String(entry);
    }
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

async function klingRequest(
  secret: string,
  path: string,
  method: string,
  body?: JsonMap,
  extraHeaders?: Record<string, string>,
): Promise<{ ok: boolean; status: number; body: JsonMap }> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${secret}`,
    Accept: "application/json",
    ...extraHeaders,
  };

  let payload: string | undefined;
  if (body && method !== "GET") {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }

  const response = await fetch(`${KLING_API}${path}`, {
    method,
    headers,
    body: payload,
  });

  let parsed: unknown;
  try {
    parsed = await response.json();
  } catch {
    parsed = { error: "Unexpected Kling response" };
  }
  const jsonBody = parsed && typeof parsed === "object"
    ? parsed as JsonMap
    : { error: "Unexpected Kling response" };
  return { ok: response.ok, status: response.status, body: jsonBody };
}

function klingErrorStatus(result: { status: number }): number {
  return result.status >= 400 && result.status < 600 ? result.status : 502;
}

function requireCardOnly(payload: JsonMap): Response | undefined {
  const method = asString(payload.paymentMethodType) ??
    asString(payload.payment_method_type) ??
    asString(payload.collectionMethod) ??
    asString(payload.collection_method);
  if (method && method !== CARD_ONLY) {
    return jsonResponse(
      { error: "only card is supported" },
      400,
    );
  }
  return undefined;
}

function requireIsk(payload: JsonMap): Response | undefined {
  const currency = asString(payload.currency);
  if (currency && currency.toUpperCase() !== ISK) {
    return jsonResponse({ error: "currency must be ISK" }, 400);
  }
  return undefined;
}

async function handleAction(
  secret: string,
  action: string,
  payload: JsonMap,
): Promise<Response> {
  switch (action) {
    case "createCheckoutSession": {
      const cardErr = requireCardOnly(payload);
      if (cardErr) return cardErr;
      const currencyErr = requireIsk(payload);
      if (currencyErr) return currencyErr;
      if (payload.amount != null || payload.items != null) {
        return jsonResponse(
          {
            error:
              "createCheckoutSession starts a recurring store subscription via productId; amount/items are not accepted",
          },
          400,
        );
      }
      const productId = asUuid(
        payload.productId ?? payload.product_id,
        "productId",
      );
      if (productId instanceof Response) return productId;

      const body: JsonMap = {
        product_id: productId,
        currency: ISK,
        payment_method_type: CARD_ONLY,
      };

      const customerId = asString(payload.customerId ?? payload.customer_id);
      if (customerId) {
        const uuid = asUuid(customerId, "customerId");
        if (uuid instanceof Response) return uuid;
        body.customer_id = uuid;
      }
      const variantId = asString(payload.variantId ?? payload.variant_id);
      if (variantId) {
        const uuid = asUuid(variantId, "variantId");
        if (uuid instanceof Response) return uuid;
        body.variant_id = uuid;
      }

      const email = asString(payload.customerEmail ?? payload.customer_email);
      const name = asString(payload.customerName ?? payload.customer_name);
      const phone = asString(payload.customerPhone ?? payload.customer_phone);
      const successUrl = asString(payload.successUrl ?? payload.success_url);
      const cancelUrl = asString(payload.cancelUrl ?? payload.cancel_url);
      const locale = asString(payload.locale);
      if (email) body.customer_email = email;
      if (name) body.customer_name = name;
      if (phone) body.customer_phone = phone;
      if (successUrl) body.success_url = successUrl;
      if (cancelUrl) body.cancel_url = cancelUrl;
      if (locale === "is" || locale === "en") body.locale = locale;

      const metadata = stringMetadata(payload.metadata) ?? {};
      const companyId = asString(payload.companyId ?? payload.company_id);
      if (companyId) metadata.company_id = companyId;
      if (!metadata.subscription_type) metadata.subscription_type = "store";
      if (Object.keys(metadata).length > 0) body.metadata = metadata;

      const extraHeaders: Record<string, string> = {};
      const idempotencyKey = asString(
        payload.idempotencyKey ?? payload.idempotency_key,
      );
      if (idempotencyKey) extraHeaders["Idempotency-Key"] = idempotencyKey;

      const result = await klingRequest(
        secret,
        "/checkout/sessions",
        "POST",
        body,
        extraHeaders,
      );
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "getCheckoutSession": {
      const sessionId = asUuid(
        payload.sessionId ?? payload.session_id ?? payload.id,
        "sessionId",
      );
      if (sessionId instanceof Response) return sessionId;
      const result = await klingRequest(
        secret,
        `/checkout/sessions/${encodeURIComponent(sessionId)}`,
        "GET",
      );
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "createBillingPortalSession": {
      const customer = asUuid(
        payload.customerId ?? payload.customer_id ?? payload.customer,
        "customerId",
      );
      if (customer instanceof Response) return customer;
      const returnUrl = asString(payload.returnUrl ?? payload.return_url);
      if (!returnUrl) {
        return jsonResponse({ error: "returnUrl is required" }, 400);
      }

      const body: JsonMap = {
        customer,
        return_url: returnUrl,
        allow_cancel: asBoolean(payload.allowCancel ?? payload.allow_cancel) ??
          true,
        allow_update_payment_method: asBoolean(
          payload.allowUpdatePaymentMethod ??
            payload.allow_update_payment_method,
        ) ?? true,
        expires_in: asInteger(payload.expiresIn ?? payload.expires_in) ?? 1800,
      };
      const subscription = asString(
        payload.subscriptionId ?? payload.subscription,
      );
      if (subscription) {
        const uuid = asUuid(subscription, "subscriptionId");
        if (uuid instanceof Response) return uuid;
        body.subscription = uuid;
      }
      const result = await klingRequest(
        secret,
        "/billing-portal/sessions",
        "POST",
        body,
      );
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "createCustomer": {
      const email = asString(payload.email);
      const name = asString(payload.name);
      if (!email || !name) {
        return jsonResponse({ error: "email and name are required" }, 400);
      }
      const body: JsonMap = { email, name };
      const phone = asString(payload.phone);
      const nationalId = asString(
        payload.nationalId ?? payload.national_id,
      );
      const externalId = asString(
        payload.externalId ?? payload.external_id,
      );
      if (phone) body.phone = phone;
      if (nationalId) body.national_id = nationalId;
      if (externalId) body.external_id = externalId;
      const metadata = stringMetadata(payload.metadata) ?? {};
      const companyId = asString(payload.companyId ?? payload.company_id);
      if (companyId) metadata.company_id = companyId;
      if (Object.keys(metadata).length > 0) body.metadata = metadata;
      const result = await klingRequest(secret, "/customers", "POST", body);
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "createSubscription": {
      const cardErr = requireCardOnly(payload);
      if (cardErr) return cardErr;
      const customerId = asUuid(
        payload.customerId ?? payload.customer_id,
        "customerId",
      );
      if (customerId instanceof Response) return customerId;
      const productId = asUuid(
        payload.productId ?? payload.product_id,
        "productId",
      );
      if (productId instanceof Response) return productId;
      const paymentMethodId = asUuid(
        payload.paymentMethodId ?? payload.payment_method_id,
        "paymentMethodId",
      );
      if (paymentMethodId instanceof Response) return paymentMethodId;

      const body: JsonMap = {
        customer_id: customerId,
        product_id: productId,
        payment_method_id: paymentMethodId,
        collection_method: CARD_ONLY,
      };
      const metadata = stringMetadata(payload.metadata) ?? {};
      const companyId = asString(payload.companyId ?? payload.company_id);
      if (companyId) metadata.company_id = companyId;
      if (!metadata.subscription_type) metadata.subscription_type = "store";
      if (Object.keys(metadata).length > 0) body.metadata = metadata;

      const result = await klingRequest(secret, "/subscriptions", "POST", body);
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "getSubscription": {
      const subscriptionId = asUuid(
        payload.subscriptionId ?? payload.subscription_id ?? payload.id,
        "subscriptionId",
      );
      if (subscriptionId instanceof Response) return subscriptionId;
      const result = await klingRequest(
        secret,
        `/subscriptions/${encodeURIComponent(subscriptionId)}`,
        "GET",
      );
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "cancelSubscription": {
      const subscriptionId = asUuid(
        payload.subscriptionId ?? payload.subscription_id ?? payload.id,
        "subscriptionId",
      );
      if (subscriptionId instanceof Response) return subscriptionId;
      const cancelImmediately =
        asBoolean(payload.cancelImmediately ?? payload.cancel_immediately) ??
          false;
      const result = await klingRequest(
        secret,
        `/subscriptions/${encodeURIComponent(subscriptionId)}/cancel`,
        "POST",
        { cancel_immediately: cancelImmediately },
      );
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    case "reactivateSubscription": {
      const subscriptionId = asUuid(
        payload.subscriptionId ?? payload.subscription_id ?? payload.id,
        "subscriptionId",
      );
      if (subscriptionId instanceof Response) return subscriptionId;
      const result = await klingRequest(
        secret,
        `/subscriptions/${encodeURIComponent(subscriptionId)}/reactivate`,
        "POST",
      );
      return jsonResponse(
        result.body,
        result.ok ? 200 : klingErrorStatus(result),
      );
    }
    default:
      return jsonResponse({ error: `Unknown action: ${action}` }, 400);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const secret = Deno.env.get("KLING_SECRET_KEY") ?? "";

  if (req.method === "GET") {
    return jsonResponse({ configured: Boolean(secret) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!secret) {
    return jsonResponse(
      { error: "KLING_SECRET_KEY is not configured on this function" },
      500,
    );
  }

  if (isLiveSecret(secret) || !isTestSecret(secret)) {
    return jsonResponse(
      { error: "KLING_SECRET_KEY must be a test-mode key" },
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
