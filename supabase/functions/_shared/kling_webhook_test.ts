// Runnable with: node --experimental-strip-types --experimental-transform-types \
//   supabase/functions/_shared/kling_webhook_test.ts
import assert from "node:assert/strict";
import { expectedKlingSignature, verifyKlingSignature } from "./kling_signature.ts";
import {
  asIskInteger,
  decideKlingWebhookEvent,
  parseKlingEvent,
  type KlingEvent,
} from "./kling_webhook.ts";

const SECRET = "test_kling_webhook_signing_secret";

function event(partial: {
  id?: string;
  type: string;
  data?: Record<string, unknown>;
  environment?: string;
}): KlingEvent {
  return {
    id: partial.id ?? "5b0c6f0e-2d7a-4f43-9a51-3f0b8f6c1e2d",
    type: partial.type,
    data: partial.data ?? { id: "9d2e4b7a-1c3f-4e8a-b6d5-0a7f2c9e4b11" },
    environment: partial.environment ?? "test",
  };
}

async function testSignature() {
  const raw = JSON.stringify({
    id: "5b0c6f0e-2d7a-4f43-9a51-3f0b8f6c1e2d",
    type: "subscription.activated",
    data: { id: "9d2e4b7a-1c3f-4e8a-b6d5-0a7f2c9e4b11", status: "active" },
    environment: "test",
  });
  const header = await expectedKlingSignature(raw, SECRET);
  assert.match(header, /^sha256=[0-9a-f]{64}$/);
  assert.equal(await verifyKlingSignature(raw, header, SECRET), true);
  assert.equal(await verifyKlingSignature(raw, null, SECRET), false);
  assert.equal(await verifyKlingSignature(raw, header, "other"), false);
  assert.equal(await verifyKlingSignature(raw + " ", header, SECRET), false);
  assert.equal(await verifyKlingSignature(raw, header.slice(0, -1) + "0", SECRET), false);
  assert.equal(await verifyKlingSignature(raw, "", SECRET), false);
}

function testIdempotencyAndEvents() {
  const subId = "9d2e4b7a-1c3f-4e8a-b6d5-0a7f2c9e4b11";
  const piId = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";

  const duplicate = decideKlingWebhookEvent({
    event: event({ type: "subscription.activated" }),
    alreadyProcessedEventId: true,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.deepEqual(duplicate, { kind: "duplicate", reason: "event_id" });

  const activated = decideKlingWebhookEvent({
    event: event({
      type: "subscription.activated",
      data: { id: subId, status: "active", metadata: { company_id: "co_1" } },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(activated.kind, "apply");
  if (activated.kind === "apply") {
    assert.equal(activated.patch.subscriptionId, subId);
    assert.equal(activated.patch.status, "active");
    assert.equal(activated.patch.paid, undefined);
    assert.equal(activated.patch.accessRevoked, false);
    assert.equal(activated.patch.companyId, "co_1");
  }

  const captured = decideKlingWebhookEvent({
    event: event({
      type: "payment_intent.captured",
      data: {
        id: piId,
        amount: 4990,
        subscription_id: subId,
        metadata: { company_id: "co_1" },
      },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(captured.kind, "apply");
  if (captured.kind === "apply") {
    assert.equal(captured.patch.paid, true);
    assert.equal(captured.patch.amountIsk, 4990);
    assert.equal(captured.patch.paymentIntentId, piId);
    assert.notEqual(captured.patch.amountIsk, 499000);
  }

  const capturedAgain = decideKlingWebhookEvent({
    event: event({
      id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
      type: "payment_intent.captured",
      data: { id: piId, amount: 4990, subscription_id: subId },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: true,
  });
  assert.deepEqual(capturedAgain, { kind: "duplicate", reason: "payment_intent" });

  const verifyCard = decideKlingWebhookEvent({
    event: event({
      type: "payment_intent.captured",
      data: { id: piId, amount: 0, subscription_id: subId },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(verifyCard.kind, "ignore");
  if (verifyCard.kind === "ignore") {
    assert.match(verifyCard.reason, /card verification/);
  }

  const oneOff = decideKlingWebhookEvent({
    event: event({
      type: "payment_intent.captured",
      data: { id: piId, amount: 4990 },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(oneOff.kind, "ignore");

  const renewed = decideKlingWebhookEvent({
    event: event({
      type: "subscription.renewed",
      data: {
        id: subId,
        payment_intent_id: "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
        amount: 4990,
        period_start: "2026-11-01T00:00:00.000Z",
        period_end: "2026-12-01T00:00:00.000Z",
      },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(renewed.kind, "apply");
  if (renewed.kind === "apply") {
    assert.equal(renewed.patch.paid, true);
    assert.equal(renewed.patch.amountIsk, 4990);
    assert.equal(renewed.patch.status, "active");
  }

  const cancelRequest = decideKlingWebhookEvent({
    event: event({
      type: "subscription.canceled",
      data: { id: subId, status: "active", cancel_at_period_end: true },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(cancelRequest.kind, "apply");
  if (cancelRequest.kind === "apply") {
    assert.equal(cancelRequest.patch.accessRevoked, false);
    assert.equal(cancelRequest.patch.cancelAtPeriodEnd, true);
    assert.equal(cancelRequest.patch.status, "active");
  }

  const cancelEnded = decideKlingWebhookEvent({
    event: event({
      type: "subscription.canceled",
      data: { id: subId, status: "canceled" },
    }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(cancelEnded.kind, "apply");
  if (cancelEnded.kind === "apply") {
    assert.equal(cancelEnded.patch.accessRevoked, true);
    assert.equal(cancelEnded.patch.status, "canceled");
  }

  const live = decideKlingWebhookEvent({
    event: event({ type: "subscription.activated", environment: "live" }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.deepEqual(live, { kind: "ignore", reason: "test-mode only" });

  const ping = decideKlingWebhookEvent({
    event: event({ type: "debug.check", data: { message: "ok" } }),
    alreadyProcessedEventId: false,
    alreadyCapturedPaymentIntentId: false,
  });
  assert.equal(ping.kind, "ignore");
}

function testParseAndIsk() {
  const parsed = parseKlingEvent({
    id: "5b0c6f0e-2d7a-4f43-9a51-3f0b8f6c1e2d",
    type: "payment_intent.captured",
    data: { amount: 4990 },
    environment: "test",
  });
  assert.ok("event" in parsed);

  assert.equal(asIskInteger(4990), 4990);
  assert.equal(asIskInteger("4990"), 4990);
  assert.equal(asIskInteger(49.9), undefined);
  assert.equal(asIskInteger(4990 * 100), 499000);
  // Caller must not multiply; 4990 stays 4990.
  assert.notEqual(asIskInteger(4990), 4990 * 100);
}

await testSignature();
testIdempotencyAndEvents();
testParseAndIsk();
console.log("kling_webhook_test.ts ok");
