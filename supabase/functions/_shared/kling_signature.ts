// HMAC-SHA256 webhook verify. Shared so kling-webhook (and later
// kling-secret, if it ever needs the same helper) never copy-paste crypto.
// X-Kling-Signature is `sha256=` + hex HMAC of the raw body.
// https://kling.is/en/docs/webhooks.md

const encoder = new TextEncoder();

function toHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  if (left.length !== right.length) return false;
  let diff = 0;
  for (let i = 0; i < left.length; i++) {
    diff |= left[i] ^ right[i];
  }
  return diff === 0;
}

export async function expectedKlingSignature(
  rawBody: string,
  secret: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(rawBody),
  );
  return `sha256=${toHex(digest)}`;
}

export async function verifyKlingSignature(
  rawBody: string,
  header: string | null | undefined,
  secret: string,
): Promise<boolean> {
  if (!header || !secret) return false;
  const expected = await expectedKlingSignature(rawBody, secret);
  return timingSafeEqual(expected, header);
}
