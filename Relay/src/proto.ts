export const TAG_LEN = 16;

const B64URL = /^[A-Za-z0-9_-]*$/;

export function b64urlEncode(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function b64urlDecode(value: unknown): Uint8Array | null {
  if (typeof value !== "string" || !B64URL.test(value)) return null;
  const padded = value.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (value.length % 4)) % 4);
  let raw: string;
  try {
    raw = atob(padded);
  } catch {
    return null;
  }
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}

export function toBytes(value: ArrayBuffer | ArrayBufferView | Uint8Array): Uint8Array {
  if (value instanceof Uint8Array) return value;
  if (ArrayBuffer.isView(value)) return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
  return new Uint8Array(value);
}

export function concat(...parts: Uint8Array[]): Uint8Array {
  const total = parts.reduce((n, p) => n + p.length, 0);
  const out = new Uint8Array(total);
  let at = 0;
  for (const p of parts) {
    out.set(p, at);
    at += p.length;
  }
  return out;
}

export function ascii(text: string): Uint8Array {
  return new TextEncoder().encode(text);
}

export function u64be(n: number): Uint8Array {
  const out = new Uint8Array(8);
  new DataView(out.buffer).setBigUint64(0, BigInt(n));
  return out;
}

const ZERO = new Uint8Array([0]);

export function helloInput(deviceId: string, ts: number): Uint8Array {
  return concat(ascii("hello"), ZERO, ascii(deviceId), ZERO, u64be(ts));
}

export function recordInput(deviceId: string, seq: number, blob: Uint8Array): Uint8Array {
  return concat(ascii(deviceId), ZERO, u64be(seq), blob);
}

export function importAuthKey(raw: Uint8Array): Promise<CryptoKey> {
  return crypto.subtle.importKey("raw", raw as BufferSource, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
}

export async function tag(key: CryptoKey, input: Uint8Array): Promise<Uint8Array> {
  const mac = await crypto.subtle.sign("HMAC", key, input as BufferSource);
  return new Uint8Array(mac, 0, TAG_LEN);
}

export function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}
