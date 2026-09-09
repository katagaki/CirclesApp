import { ascii } from "./proto";

export const APNS_SANDBOX = "https://api.sandbox.push.apple.com";
export const APNS_PRODUCTION = "https://api.push.apple.com";
export const FCM_SEND = "https://fcm.googleapis.com/v1/projects";
export const TOKEN_TTL_MS = 50 * 60 * 1000;

export type Platform = "apns" | "fcm";
export type Environment = "sandbox" | "production";
export type Outcome = "sent" | "gone" | "failed" | "unconfigured";

export interface PushEnv {
  APNS_TEAM_ID?: string;
  APNS_TOPIC?: string;
  APNS_SANDBOX_KEY_ID?: string;
  APNS_SANDBOX_KEY_P8?: string;
  APNS_PRODUCTION_KEY_ID?: string;
  APNS_PRODUCTION_KEY_P8?: string;
  FCM_SERVICE_ACCOUNT?: string;
}

export interface Target {
  platform: Platform;
  token: string;
  environment: Environment;
}

interface Cached {
  value: string;
  at: number;
}

const bearers: { [slot: string]: Cached } = {};

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlText(text: string): string {
  return b64url(new TextEncoder().encode(text));
}

function pkcs8(pem: string): Uint8Array {
  const body = pem.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const raw = atob(body);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}

async function jws(key: CryptoKey, algorithm: string | object, header: object, claims: object): Promise<string> {
  const body = `${b64urlText(JSON.stringify(header))}.${b64urlText(JSON.stringify(claims))}`;
  const signature = await crypto.subtle.sign(algorithm as never, key, ascii(body) as BufferSource);
  return `${body}.${b64url(new Uint8Array(signature))}`;
}

async function cache(slot: string, mint: () => Promise<string | null>): Promise<string | null> {
  const held = bearers[slot];
  if (held && Date.now() - held.at < TOKEN_TTL_MS) return held.value;
  const value = await mint();
  if (value) bearers[slot] = { value, at: Date.now() };
  return value;
}

export function resetBearers(): void {
  for (const slot of Object.keys(bearers)) delete bearers[slot];
}

function apnsCredentials(env: PushEnv, environment: Environment): { keyId: string; pem: string } | null {
  const keyId = environment === "production" ? env.APNS_PRODUCTION_KEY_ID : env.APNS_SANDBOX_KEY_ID;
  const pem = environment === "production" ? env.APNS_PRODUCTION_KEY_P8 : env.APNS_SANDBOX_KEY_P8;
  if (!keyId || !pem || !env.APNS_TEAM_ID || !env.APNS_TOPIC) return null;
  return { keyId, pem };
}

async function apnsBearer(env: PushEnv, environment: Environment): Promise<string | null> {
  const credentials = apnsCredentials(env, environment);
  if (!credentials) return null;
  return cache(`apns:${environment}:${credentials.keyId}`, async () => {
    const key = await crypto.subtle.importKey(
      "pkcs8",
      pkcs8(credentials.pem) as BufferSource,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"],
    );
    return jws(
      key,
      { name: "ECDSA", hash: "SHA-256" },
      { alg: "ES256", kid: credentials.keyId },
      { iss: env.APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) },
    );
  });
}

async function apns(env: PushEnv, target: Target): Promise<Outcome> {
  const bearer = await apnsBearer(env, target.environment);
  if (!bearer) return "unconfigured";
  const host = target.environment === "production" ? APNS_PRODUCTION : APNS_SANDBOX;
  const response = await fetch(`${host}/3/device/${target.token}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${bearer}`,
      "apns-topic": env.APNS_TOPIC!,
      "apns-push-type": "background",
      "apns-priority": "5",
      "apns-expiration": String(Math.floor(Date.now() / 1000) + 300),
    },
    body: JSON.stringify({ aps: { "content-available": 1 } }),
  });
  if (response.ok) return "sent";
  if (response.status === 410 || response.status === 400) return "gone";
  return "failed";
}

interface ServiceAccount {
  project_id?: string;
  client_email?: string;
  private_key?: string;
  token_uri?: string;
}

function serviceAccount(env: PushEnv): ServiceAccount | null {
  if (!env.FCM_SERVICE_ACCOUNT) return null;
  try {
    const parsed = JSON.parse(env.FCM_SERVICE_ACCOUNT) as ServiceAccount;
    if (!parsed.project_id || !parsed.client_email || !parsed.private_key) return null;
    return parsed;
  } catch {
    return null;
  }
}

async function fcmBearer(account: ServiceAccount): Promise<string | null> {
  const endpoint = account.token_uri ?? "https://oauth2.googleapis.com/token";
  return cache(`fcm:${account.client_email}`, async () => {
    const key = await crypto.subtle.importKey(
      "pkcs8",
      pkcs8(account.private_key!) as BufferSource,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const now = Math.floor(Date.now() / 1000);
    const assertion = await jws(
      key,
      "RSASSA-PKCS1-v1_5",
      { alg: "RS256", typ: "JWT" },
      {
        iss: account.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: endpoint,
        iat: now,
        exp: now + 3600,
      },
    );
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });
    if (!response.ok) return null;
    const body = (await response.json()) as { access_token?: string };
    return body.access_token ?? null;
  });
}

async function fcm(env: PushEnv, target: Target): Promise<Outcome> {
  const account = serviceAccount(env);
  if (!account) return "unconfigured";
  const bearer = await fcmBearer(account);
  if (!bearer) return "failed";
  const response = await fetch(`${FCM_SEND}/${account.project_id}/messages:send`, {
    method: "POST",
    headers: { authorization: `Bearer ${bearer}`, "content-type": "application/json" },
    body: JSON.stringify({
      message: {
        token: target.token,
        data: { t: "sync" },
        android: { priority: "HIGH" },
      },
    }),
  });
  if (response.ok) return "sent";
  if (response.status === 404 || response.status === 400) return "gone";
  return "failed";
}

export async function push(env: PushEnv, target: Target): Promise<Outcome> {
  try {
    return target.platform === "apns" ? await apns(env, target) : await fcm(env, target);
  } catch {
    return "failed";
  }
}
