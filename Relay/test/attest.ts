import { concat, sha256 } from "../src/proto";

export function cborHeader(major: number, length: number): number[] {
  if (length < 24) return [(major << 5) | length];
  if (length < 256) return [(major << 5) | 24, length];
  if (length < 65536) return [(major << 5) | 25, length >> 8, length & 0xff];
  return [(major << 5) | 26, (length >>> 24) & 0xff, (length >> 16) & 0xff, (length >> 8) & 0xff, length & 0xff];
}

export function cborBytes(value: Uint8Array): number[] {
  return [...cborHeader(2, value.length), ...value];
}

export function cborText(value: string): number[] {
  const bytes = new TextEncoder().encode(value);
  return [...cborHeader(3, bytes.length), ...bytes];
}

export function cborMap(entries: [string, number[]][]): Uint8Array {
  const out = [...cborHeader(5, entries.length)];
  for (const [key, value] of entries) out.push(...cborText(key), ...value);
  return new Uint8Array(out);
}

export function cborArray(items: number[][]): number[] {
  const out = [...cborHeader(4, items.length)];
  for (const item of items) out.push(...item);
  return out;
}

/** Re-encodes a WebCrypto P-256 signature as the DER that App Attest carries. */
export function derSignature(raw: Uint8Array): Uint8Array {
  const integer = (bytes: Uint8Array): number[] => {
    const value = [...bytes];
    while (value.length > 1 && value[0] === 0) value.shift();
    if (value[0] & 0x80) value.unshift(0);
    return [0x02, value.length, ...value];
  };
  const body = [...integer(raw.subarray(0, 32)), ...integer(raw.subarray(32))];
  return new Uint8Array([0x30, body.length, ...body]);
}

export function counterBytes(counter: number): Uint8Array {
  const out = new Uint8Array(4);
  new DataView(out.buffer).setUint32(0, counter);
  return out;
}

export async function appIdHash(teamId: string, bundleId: string): Promise<Uint8Array> {
  return sha256(new TextEncoder().encode(`${teamId}.${bundleId}`));
}

export interface AssertionKeys {
  publicKey: Uint8Array;
  sign: (message: Uint8Array) => Promise<Uint8Array>;
}

export async function assertionKeys(): Promise<AssertionKeys> {
  const pair = (await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, [
    "sign",
    "verify",
  ])) as CryptoKeyPair;
  const spki = new Uint8Array((await crypto.subtle.exportKey("spki", pair.publicKey)) as ArrayBuffer);
  return {
    publicKey: spki,
    sign: async (message) =>
      new Uint8Array(
        await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, pair.privateKey, message as BufferSource),
      ),
  };
}

/** Builds the assertion CBOR a device sends once it is already enrolled. */
export async function assertion(
  keys: AssertionKeys,
  rpIdHash: Uint8Array,
  counter: number,
  clientDataHash: Uint8Array,
): Promise<string> {
  const authData = concat(rpIdHash, new Uint8Array([0]), counterBytes(counter));
  const nonce = await sha256(concat(authData, clientDataHash));
  const signature = derSignature(await keys.sign(nonce));
  const object = cborMap([
    ["signature", cborBytes(signature)],
    ["authenticatorData", cborBytes(authData)],
  ]);
  return base64url(object);
}

export function base64url(bytes: Uint8Array): string {
  let text = "";
  for (const byte of bytes) text += String.fromCharCode(byte);
  return btoa(text).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function serviceAccountJson(): Promise<string> {
  const pair = (await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  )) as CryptoKeyPair;
  const der = new Uint8Array((await crypto.subtle.exportKey("pkcs8", pair.privateKey)) as ArrayBuffer);
  let text = "";
  for (const byte of der) text += String.fromCharCode(byte);
  const body = btoa(text).match(/.{1,64}/g)!.join("\n");
  return JSON.stringify({
    project_id: "circles-test",
    client_email: "relay@circles-test.iam.gserviceaccount.com",
    private_key: `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----\n`,
    token_uri: "https://oauth2.googleapis.com/token",
  });
}
