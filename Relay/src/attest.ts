import "reflect-metadata";
import * as x509 from "@peculiar/x509";
import { decodeCbor, type CborValue } from "./cbor";
import { googleBearer, serviceAccount } from "./push";
import { ascii, b64urlDecode, b64urlEncode, concat, sha256, timingSafeEqual } from "./proto";

export const APPLE_ROOT_PEM = `-----BEGIN CERTIFICATE-----
MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYw
JAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwK
QXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNa
Fw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlv
biBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9y
bmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdh
NbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9au
Yen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/
MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYw
CgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn
53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3VcE3iexZZtKeYnpqtijV
oyFraWVIyd/dganmrduC1bmTBGwD
-----END CERTIFICATE-----`;

const NONCE_OID = "1.2.840.113635.100.8.2";
const PLAY_SCOPE = "https://www.googleapis.com/auth/playintegrity";
const PLAY_DECODE = "https://playintegrity.googleapis.com/v1";
const AAGUID_PRODUCTION = "appattest";
const AAGUID_DEVELOPMENT = "appattestdevelop";
const VERDICT_RANK: { [verdict: string]: number } = {
  MEETS_BASIC_INTEGRITY: 1,
  MEETS_DEVICE_INTEGRITY: 2,
  MEETS_STRONG_INTEGRITY: 3,
};
const MIN_VERDICT: { [name: string]: number } = { basic: 1, device: 2, strong: 3 };

export const ATTEST_SKEW_MS = 300_000;
export const MAX_ATTEST_FRAME_BYTES = 16_384;
export const MAX_INTEGRITY_TOKEN = 8_192;

export type AttestKind = "appattest" | "playintegrity";
export type AttestMode = "off" | "optional" | "required";

export interface AttestEnv {
  ATTEST_MODE?: string;
  APP_ATTEST_TEAM_ID?: string;
  APP_ATTEST_BUNDLE_ID?: string;
  APP_ATTEST_ENVIRONMENT?: string;
  PLAY_PACKAGE_NAME?: string;
  PLAY_MIN_VERDICT?: string;
  PLAY_SERVICE_ACCOUNT?: string;
  FCM_SERVICE_ACCOUNT?: string;
}

export interface Enrolled {
  kind: AttestKind;
  keyId: Uint8Array | null;
  pubkey: Uint8Array | null;
  counter: number;
}

export type Verified =
  | { ok: true; kind: AttestKind; keyId: Uint8Array | null; pubkey: Uint8Array | null; counter: number }
  | { ok: false; reason: string };

let provider = false;

function fail(reason: string): Verified {
  return { ok: false, reason };
}

export function attestMode(env: AttestEnv): AttestMode {
  const mode = env.ATTEST_MODE;
  return mode === "required" || mode === "optional" ? mode : "off";
}

export async function verifyAttestation(
  env: AttestEnv,
  evidence: unknown,
  clientDataHash: Uint8Array,
  enrolled: Enrolled | null,
): Promise<Verified> {
  if (!evidence || typeof evidence !== "object") return fail("bad attestation");
  const kind = (evidence as { t?: unknown }).t;
  if (kind !== "appattest" && kind !== "playintegrity") return fail("unknown attestation kind");
  if (enrolled && enrolled.kind !== kind) return fail("attestation kind changed");
  try {
    return kind === "appattest"
      ? await appAttest(env, evidence as AppAttestEvidence, clientDataHash, enrolled)
      : await playIntegrity(env, evidence as PlayEvidence, clientDataHash);
  } catch {
    return fail("attestation could not be checked");
  }
}

interface AppAttestEvidence {
  k?: unknown;
  o?: unknown;
  s?: unknown;
}

async function appAttest(
  env: AttestEnv,
  evidence: AppAttestEvidence,
  clientDataHash: Uint8Array,
  enrolled: Enrolled | null,
): Promise<Verified> {
  const teamId = env.APP_ATTEST_TEAM_ID;
  const bundleId = env.APP_ATTEST_BUNDLE_ID;
  if (!teamId || !bundleId) return fail("app attest unconfigured");
  const keyId = b64urlDecode(evidence.k);
  if (!keyId || keyId.length !== 32) return fail("bad key id");
  const appId = await sha256(ascii(`${teamId}.${bundleId}`));
  if (typeof evidence.o === "string") return enroll(env, keyId, evidence.o, clientDataHash, appId, enrolled);
  if (typeof evidence.s === "string") return reassert(evidence.s, clientDataHash, appId, enrolled);
  return fail("no attestation or assertion");
}

async function enroll(
  env: AttestEnv,
  keyId: Uint8Array,
  object: string,
  clientDataHash: Uint8Array,
  appId: Uint8Array,
  enrolled: Enrolled | null,
): Promise<Verified> {
  if (enrolled?.keyId && enrolled.counter > 0 && timingSafeEqual(enrolled.keyId, keyId)) {
    return fail("key already enrolled");
  }
  const raw = b64urlDecode(object);
  if (!raw) return fail("bad attestation object");
  const decoded = decodeCbor(raw);
  const map = asMap(decoded);
  if (!map) return fail("bad attestation object");
  if (map.fmt !== "apple-appattest") return fail("bad attestation format");
  const authData = map.authData;
  if (!(authData instanceof Uint8Array)) return fail("bad authenticator data");
  const statement = asMap(map.attStmt);
  if (!statement) return fail("bad attestation statement");
  const offered = statement.x5c;
  if (!Array.isArray(offered) || offered.length < 2) return fail("bad certificate chain");
  const chain: Uint8Array[] = [];
  for (const der of offered) {
    if (!(der instanceof Uint8Array)) return fail("bad certificate");
    chain.push(der);
  }

  const leaf = await verifyChain(chain);
  if (!leaf) return fail("untrusted certificate chain");

  const embedded = certificateNonce(leaf);
  const nonce = await sha256(concat(authData, clientDataHash));
  if (!embedded || !timingSafeEqual(embedded, nonce)) return fail("attestation nonce mismatch");

  const spki = new Uint8Array(leaf.publicKey.rawData as ArrayBuffer);
  const key = await crypto.subtle.importKey(
    "spki",
    spki as BufferSource,
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["verify"],
  );
  const point = new Uint8Array((await crypto.subtle.exportKey("raw", key)) as ArrayBuffer);
  if (!timingSafeEqual(await sha256(point), keyId)) return fail("key id mismatch");

  const parsed = parseAuthData(authData);
  if (!parsed || !parsed.aaguid || !parsed.credentialId) return fail("bad authenticator data");
  if (!timingSafeEqual(parsed.rpIdHash, appId)) return fail("app id mismatch");
  if (parsed.counter !== 0) return fail("attested counter is not zero");
  if (!environmentAllows(parsed.aaguid, env.APP_ATTEST_ENVIRONMENT)) return fail("wrong app attest environment");
  if (!timingSafeEqual(parsed.credentialId, keyId)) return fail("credential id mismatch");

  return { ok: true, kind: "appattest", keyId, pubkey: spki, counter: 0 };
}

async function reassert(
  assertion: string,
  clientDataHash: Uint8Array,
  appId: Uint8Array,
  enrolled: Enrolled | null,
): Promise<Verified> {
  if (!enrolled || !enrolled.pubkey) return fail("device is not enrolled");
  const raw = b64urlDecode(assertion);
  if (!raw) return fail("bad assertion");
  const map = asMap(decodeCbor(raw));
  if (!map) return fail("bad assertion");
  const authData = map.authenticatorData;
  const signature = map.signature;
  if (!(authData instanceof Uint8Array) || !(signature instanceof Uint8Array)) return fail("bad assertion");

  const parsed = parseAuthData(authData);
  if (!parsed) return fail("bad authenticator data");
  if (!timingSafeEqual(parsed.rpIdHash, appId)) return fail("app id mismatch");
  if (parsed.counter <= enrolled.counter) return fail("assertion counter did not advance");

  const flat = flatSignature(signature);
  if (!flat) return fail("bad signature encoding");
  const key = await crypto.subtle.importKey(
    "spki",
    enrolled.pubkey as BufferSource,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["verify"],
  );
  const nonce = await sha256(concat(authData, clientDataHash));
  const good = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    flat as BufferSource,
    nonce as BufferSource,
  );
  if (!good) return fail("bad assertion signature");
  return { ok: true, kind: "appattest", keyId: enrolled.keyId, pubkey: enrolled.pubkey, counter: parsed.counter };
}

async function verifyChain(chain: Uint8Array[]): Promise<x509.X509Certificate | null> {
  if (!provider) {
    x509.cryptoProvider.set(crypto as unknown as Crypto);
    provider = true;
  }
  const root = new x509.X509Certificate(APPLE_ROOT_PEM);
  let full: x509.X509Certificate[];
  try {
    full = [...chain.map((der) => new x509.X509Certificate(der as BufferSource)), root];
  } catch {
    return null;
  }
  const now = new Date();
  for (let i = 0; i < full.length; i++) {
    const cert = full[i];
    if (cert.notBefore > now || cert.notAfter < now) return null;
    const parent = full[i + 1] ?? root;
    if (!(await cert.verify({ publicKey: parent.publicKey, signatureOnly: true }))) return null;
  }
  return full[0];
}

function certificateNonce(cert: x509.X509Certificate): Uint8Array | null {
  const extension = cert.getExtension(NONCE_OID);
  if (!extension) return null;
  const value = new Uint8Array(extension.value);
  let at = 0;
  const header = (tag: number): number | null => {
    if (value[at] !== tag) return null;
    at += 1;
    let length = value[at++];
    if (length === undefined) return null;
    if (length & 0x80) {
      const count = length & 0x7f;
      if (count < 1 || count > 2) return null;
      length = 0;
      for (let i = 0; i < count; i++) {
        const byte = value[at++];
        if (byte === undefined) return null;
        length = (length << 8) | byte;
      }
    }
    return length;
  };
  if (header(0x30) === null) return null;
  if (header(0xa1) === null) return null;
  if (header(0x04) !== 32 || at + 32 > value.length) return null;
  return value.slice(at, at + 32);
}

interface AuthData {
  rpIdHash: Uint8Array;
  counter: number;
  aaguid: Uint8Array | null;
  credentialId: Uint8Array | null;
}

function parseAuthData(data: Uint8Array): AuthData | null {
  if (data.length < 37) return null;
  const view = new DataView(data.buffer, data.byteOffset, data.byteLength);
  const rpIdHash = data.slice(0, 32);
  const counter = view.getUint32(33);
  if (data.length === 37) return { rpIdHash, counter, aaguid: null, credentialId: null };
  if (data.length < 55) return null;
  const length = view.getUint16(53);
  if (length !== 32 || data.length < 55 + length) return null;
  return { rpIdHash, counter, aaguid: data.slice(37, 53), credentialId: data.slice(55, 55 + length) };
}

function environmentAllows(aaguid: Uint8Array, environment: string | undefined): boolean {
  const text = new TextDecoder().decode(aaguid).replace(/\0+$/, "");
  if (environment === "development") return text === AAGUID_DEVELOPMENT || text === AAGUID_PRODUCTION;
  return text === AAGUID_PRODUCTION;
}

function flatSignature(der: Uint8Array): Uint8Array | null {
  let at = 0;
  if (der[at++] !== 0x30) return null;
  let total = der[at++];
  if (total === undefined) return null;
  if (total & 0x80) {
    if ((total & 0x7f) !== 1) return null;
    total = der[at++];
    if (total === undefined) return null;
  }
  if (at + total !== der.length) return null;
  const integer = (): Uint8Array | null => {
    if (der[at++] !== 0x02) return null;
    const length = der[at++];
    if (length === undefined || length === 0 || length > 33 || at + length > der.length) return null;
    const value = der.slice(at, at + length);
    at += length;
    return value;
  };
  const r = integer();
  const s = integer();
  if (!r || !s || at !== der.length) return null;
  const out = new Uint8Array(64);
  const place = (value: Uint8Array, offset: number): boolean => {
    let bytes = value;
    while (bytes.length > 32 && bytes[0] === 0) bytes = bytes.subarray(1);
    if (bytes.length > 32) return false;
    out.set(bytes, offset + 32 - bytes.length);
    return true;
  };
  return place(r, 0) && place(s, 32) ? out : null;
}

interface PlayEvidence {
  tk?: unknown;
}

interface PlayPayload {
  requestDetails?: { requestPackageName?: unknown; requestHash?: unknown; timestampMillis?: unknown };
  appIntegrity?: { appRecognitionVerdict?: unknown; packageName?: unknown };
  deviceIntegrity?: { deviceRecognitionVerdict?: unknown };
}

async function playIntegrity(env: AttestEnv, evidence: PlayEvidence, clientDataHash: Uint8Array): Promise<Verified> {
  const name = env.PLAY_PACKAGE_NAME;
  const account = serviceAccount(env.PLAY_SERVICE_ACCOUNT ?? env.FCM_SERVICE_ACCOUNT);
  if (!name || !account) return fail("play integrity unconfigured");
  const token = evidence.tk;
  if (typeof token !== "string" || token.length === 0 || token.length > MAX_INTEGRITY_TOKEN) {
    return fail("bad integrity token");
  }
  const bearer = await googleBearer(account, PLAY_SCOPE);
  if (!bearer) return fail("play integrity token exchange failed");

  const response = await fetch(`${PLAY_DECODE}/${encodeURIComponent(name)}:decodeIntegrityToken`, {
    method: "POST",
    headers: { authorization: `Bearer ${bearer}`, "content-type": "application/json" },
    body: JSON.stringify({ integrityToken: token }),
  });
  if (!response.ok) return fail("play integrity rejected the token");
  const body = (await response.json()) as { tokenPayloadExternal?: PlayPayload };
  const payload = body.tokenPayloadExternal;
  if (!payload) return fail("no integrity payload");

  const details = payload.requestDetails;
  if (details?.requestPackageName !== name) return fail("integrity package mismatch");
  if (details?.requestHash !== b64urlEncode(clientDataHash)) return fail("integrity request hash mismatch");
  const at = Number(details?.timestampMillis ?? NaN);
  if (!Number.isFinite(at) || Math.abs(Date.now() - at) > ATTEST_SKEW_MS) return fail("stale integrity token");

  if (payload.appIntegrity?.packageName !== name) return fail("integrity package mismatch");
  if (payload.appIntegrity?.appRecognitionVerdict !== "PLAY_RECOGNIZED") return fail("app not recognised by play");

  const verdicts = payload.deviceIntegrity?.deviceRecognitionVerdict;
  if (!Array.isArray(verdicts)) return fail("no device verdict");
  let best = 0;
  for (const verdict of verdicts) best = Math.max(best, VERDICT_RANK[String(verdict)] ?? 0);
  if (best < (MIN_VERDICT[env.PLAY_MIN_VERDICT ?? "device"] ?? 2)) return fail("device integrity too low");

  return { ok: true, kind: "playintegrity", keyId: null, pubkey: null, counter: 0 };
}

function asMap(value: CborValue | null): { [key: string]: CborValue } | null {
  if (!value || typeof value !== "object" || Array.isArray(value) || value instanceof Uint8Array) return null;
  return value as { [key: string]: CborValue };
}
