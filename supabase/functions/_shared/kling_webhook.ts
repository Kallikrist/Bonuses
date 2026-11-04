// Pure Kling webhook decisions. No Deno, no secrets, no I/O.
// Keep behaviour in sync with test/kling_webhook_handling_test.dart
// (source inspection) and supabase/functions/_shared/kling_webhook_test.ts.
// Docs: https://kling.is/en/docs/webhooks.md
// OpenAPI: https://api.kling.is/docs/json

export type JsonMap = Record<string, unknown>;

export const HANDLED_EVENT_TYPES = [
  "subscription.activated",
  "payment_intent.captured",
  "subscription.renewed",
  "subscription.canceled",
] as const;

export type HandledEventType = typeof HANDLED_EVENT_TYPES[number];

export type KlingEvent = {
  id: string;
  type: string;
  created_at?: string;
  data: JsonMap;
  merchant_id?: string;
  environment?: string;
};

export type KlingSubscriptionPatch = {
  subscriptionId: string;
  eventId: string;
  eventType: string;
  status?: string;
  paid?: boolean;
  accessRevoked?: boolean;
  cancelAtPeriodEnd?: boolean;
  amountIsk?: number;
  currency?: string;
  periodStart?: string;
  periodEnd?: string;
  paymentIntentId?: string;
  companyId?: string;
};

export type KlingDecision =
  | { kind: "duplicate"; reason: "event_id" | "payment_intent" }
  | { kind: "ignore"; reason: string }
  | { kind: "apply"; patch: KlingSubscriptionPatch };

export type KlingDecideInput = {
  event: KlingEvent;
  alreadyProcessedEventId: boolean;
  alreadyCapturedPaymentIntentId: boolean;
};

export function asString(value: unknown): string | undefined {
  if (typeof value === "string" && value.trim().length > 0) {
    return value.trim();
  }
  return undefined;
}

export function pick(
  data: JsonMap,
  ...keys: string[]
): unknown {
  for (const key of keys) {
    if (data[key] != null) return data[key];
  }
  return undefined;
}

function pickString(data: JsonMap, ...keys: string[]): string | undefined {
  return asString(pick(data, ...keys));
}

function pickBoolean(data: JsonMap, ...keys: string[]): boolean | undefined {
  const value = pick(data, ...keys);
  if (typeof value === "boolean") return value;
  return undefined;
}

// ISK is zero-decimal: 4990 means 4.990 kr. Never multiply by 100.
export function asIskInteger(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }
  if (typeof value === "string" && /^-?\d+$/.test(value.trim())) {
    const parsed = Number(value.trim());
    if (Number.isInteger(parsed)) return parsed;
  }
  return undefined;
}

function asIsoTimestamp(value: unknown): string | undefined {
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) return new Date(parsed).toISOString();
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    const ms = value > 10_000_000_000 ? value : value * 1_000;
    const date = new Date(ms);
    if (!Number.isNaN(date.getTime())) return date.toISOString();
  }
  return undefined;
}

export function isHandledEventType(type: string): type is HandledEventType {
  return (HANDLED_EVENT_TYPES as readonly string[]).includes(type);
}

export function parseKlingEvent(
  body: unknown,
): { event: KlingEvent } | { error: string } {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return { error: "event body must be an object" };
  }
  const raw = body as JsonMap;
  const id = asString(raw.id);
  const type = asString(raw.type);
  if (!id || !type) {
    return { error: "event id and type are required" };
  }
  const data = raw.data && typeof raw.data === "object" && !Array.isArray(raw.data)
    ? raw.data as JsonMap
    : {};
  return {
    event: {
      id,
      type,
      created_at: asString(raw.created_at),
      data,
      merchant_id: asString(raw.merchant_id),
      environment: asString(raw.environment)?.toLowerCase(),
    },
  };
}

function companyIdFrom(data: JsonMap): string | undefined {
  const metadata = data.metadata;
  if (metadata && typeof metadata === "object" && !Array.isArray(metadata)) {
    const fromMeta = pickString(
      metadata as JsonMap,
      "company_id",
      "companyId",
    );
    if (fromMeta) return fromMeta;
  }
  return pickString(data, "company_id", "companyId");
}

function subscriptionIdFrom(
  event: KlingEvent,
  fallbackToEventObjectId: boolean,
): string | undefined {
  const fromData = pickString(
    event.data,
    "subscription_id",
    "subscriptionId",
    "subscription",
  );
  if (fromData) return fromData;
  if (fallbackToEventObjectId) return asString(event.data.id);
  return undefined;
}

export function decideKlingWebhookEvent(
  input: KlingDecideInput,
): KlingDecision {
  if (input.alreadyProcessedEventId) {
    return { kind: "duplicate", reason: "event_id" };
  }

  const { event } = input;
  if (event.environment && event.environment !== "test") {
    return { kind: "ignore", reason: "test-mode only" };
  }

  if (!isHandledEventType(event.type)) {
    return { kind: "ignore", reason: `unhandled event ${event.type}` };
  }

  switch (event.type) {
    case "subscription.activated": {
      // Becomes active after trial. Sent before the first charge: not paid.
      const subscriptionId = subscriptionIdFrom(event, true);
      if (!subscriptionId) {
        return { kind: "ignore", reason: "missing subscription id" };
      }
      return {
        kind: "apply",
        patch: {
          subscriptionId,
          eventId: event.id,
          eventType: event.type,
          status: "active",
          accessRevoked: false,
          cancelAtPeriodEnd: false,
          companyId: companyIdFrom(event.data),
          periodStart: asIsoTimestamp(
            pick(event.data, "period_start", "periodStart", "current_period_start"),
          ),
          periodEnd: asIsoTimestamp(
            pick(event.data, "period_end", "periodEnd", "current_period_end"),
          ),
        },
      };
    }
    case "payment_intent.captured": {
      // First charge after trial (and any other captured subscription charge).
      // amount 0 is a card verification, not a sale.
      const amount = asIskInteger(pick(event.data, "amount"));
      if (amount === 0) {
        return { kind: "ignore", reason: "card verification (amount 0)" };
      }
      const subscriptionId = subscriptionIdFrom(event, false);
      if (!subscriptionId) {
        return { kind: "ignore", reason: "captured payment is not a subscription charge" };
      }
      const paymentIntentId = pickString(event.data, "id", "payment_intent_id", "paymentIntentId");
      if (paymentIntentId && input.alreadyCapturedPaymentIntentId) {
        return { kind: "duplicate", reason: "payment_intent" };
      }
      if (amount == null) {
        return { kind: "ignore", reason: "missing ISK integer amount" };
      }
      return {
        kind: "apply",
        patch: {
          subscriptionId,
          eventId: event.id,
          eventType: event.type,
          status: "active",
          paid: true,
          accessRevoked: false,
          amountIsk: amount,
          currency: pickString(event.data, "currency")?.toUpperCase() ?? "ISK",
          paymentIntentId,
          companyId: companyIdFrom(event.data),
          periodStart: asIsoTimestamp(
            pick(event.data, "period_start", "periodStart"),
          ),
          periodEnd: asIsoTimestamp(
            pick(event.data, "period_end", "periodEnd"),
          ),
        },
      };
    }
    case "subscription.renewed": {
      const subscriptionId = subscriptionIdFrom(event, true);
      if (!subscriptionId) {
        return { kind: "ignore", reason: "missing subscription id" };
      }
      const paymentIntentId = pickString(
        event.data,
        "payment_intent_id",
        "paymentIntentId",
      );
      if (paymentIntentId && input.alreadyCapturedPaymentIntentId) {
        return { kind: "duplicate", reason: "payment_intent" };
      }
      const amount = asIskInteger(pick(event.data, "amount"));
      return {
        kind: "apply",
        patch: {
          subscriptionId,
          eventId: event.id,
          eventType: event.type,
          status: "active",
          paid: true,
          accessRevoked: false,
          cancelAtPeriodEnd: false,
          amountIsk: amount,
          currency: pickString(event.data, "currency")?.toUpperCase() ?? "ISK",
          paymentIntentId,
          companyId: companyIdFrom(event.data),
          periodStart: asIsoTimestamp(
            pick(event.data, "period_start", "periodStart", "current_period_start"),
          ),
          periodEnd: asIsoTimestamp(
            pick(event.data, "period_end", "periodEnd", "current_period_end"),
          ),
        },
      };
    }
    case "subscription.canceled": {
      // Fires on period-end cancel request (still active) and again when ended.
      // Only revoke access when status is canceled.
      const subscriptionId = subscriptionIdFrom(event, true);
      if (!subscriptionId) {
        return { kind: "ignore", reason: "missing subscription id" };
      }
      const status = pickString(event.data, "status")?.toLowerCase();
      if (!status) {
        return { kind: "ignore", reason: "canceled event missing status" };
      }
      const cancelAtPeriodEnd =
        pickBoolean(event.data, "cancel_at_period_end", "cancelAtPeriodEnd") ??
          false;
      if (status === "canceled" || status === "cancelled") {
        return {
          kind: "apply",
          patch: {
            subscriptionId,
            eventId: event.id,
            eventType: event.type,
            status: "canceled",
            accessRevoked: true,
            cancelAtPeriodEnd: true,
            companyId: companyIdFrom(event.data),
          },
        };
      }
      return {
        kind: "apply",
        patch: {
          subscriptionId,
          eventId: event.id,
          eventType: event.type,
          status,
          accessRevoked: false,
          cancelAtPeriodEnd,
          companyId: companyIdFrom(event.data),
        },
      };
    }
  }
}
