import { AUTHENTICATED_HEADER, readEvidence, readHello, rejection } from "./admission";
import { Room, HELLO_SKEW_SECONDS, MAX_IMAGE_BYTES } from "./room";
import { Identity } from "./identity";
import type { PushEnv } from "./push";
import { type AttestEnv, type Verified, attestMode, isLoopback, verifyAttestation } from "./attest";
import { DEVICE_ID, attestInput, b64urlDecode, b64urlEncode, sha256 } from "./proto";

export { Room, Identity };

const ROOM_PATH = /^\/r\/([0-9a-f]{32})$/;
const IMAGE_PATH = /^\/r\/([0-9a-f]{32})\/i\/[0-9a-f]{32}$/;
const HOMEPAGE = "https://github.com/katagaki/CirclesApp";

export interface Env extends PushEnv, AttestEnv {
  ROOM: DurableObjectNamespace<Room>;
  IDENTITY: DurableObjectNamespace<Identity>;
  ATTEST_LIMITER: RateLimit;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health") return new Response("ok");
    if (url.pathname === "/" && url.search === "") return Response.redirect(HOMEPAGE, 302);
    const image = IMAGE_PATH.exec(url.pathname);
    if (image) return routeImage(request, env, image[1]);
    const match = ROOM_PATH.exec(url.pathname);
    if (!match) return new Response("bad request", { status: 400 });
    if (request.method !== "GET" || request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("expected websocket", { status: 400 });
    }
    const hello = readHello(request);
    if (!hello) return rejection(401, "auth", "authenticated hello required");
    const frame = hello.frame;
    if (typeof frame.d !== "string" || !DEVICE_ID.test(frame.d)) return rejection(400, "proto", "bad device id");
    if (!Number.isSafeInteger(frame.ts) || (frame.ts as number) < 0) return rejection(400, "proto", "bad timestamp");
    if (Math.abs(Math.floor(Date.now() / 1000) - (frame.ts as number)) > HELLO_SKEW_SECONDS) return rejection(401, "auth", "stale hello");
    const mode = attestMode(env, isLoopback(url.hostname));
    const evidence = readEvidence(request);
    if (mode !== "off" && (evidence !== undefined || mode === "required")) {
      if (!evidence) return rejection(403, "attest", "attestation required");
      const limit = await env.ATTEST_LIMITER.limit({ key: request.headers.get("CF-Connecting-IP") ?? "unknown" });
      if (!limit.success) return rejection(429, "rate", "too many attestations");
      const hash = await sha256(attestInput(match[1], hello.bytes));
      const result = await attest(env, evidence, hash);
      if (!result.ok) return rejection(403, "attest", result.reason);
    }
    const forwarded = new Request(request);
    forwarded.headers.set(AUTHENTICATED_HEADER, "1");
    return env.ROOM.get(env.ROOM.idFromName(match[1])).fetch(forwarded);
  },
};

function routeImage(request: Request, env: Env, room: string): Promise<Response> | Response {
  if (request.method === "PUT") {
    const length = Number(request.headers.get("Content-Length") ?? NaN);
    if (!Number.isSafeInteger(length) || length <= 0) return rejection(411, "proto", "content length required");
    if (length > MAX_IMAGE_BYTES) return rejection(413, "proto", "image too large");
  } else if (request.method !== "GET") {
    return new Response("method not allowed", { status: 405 });
  }
  return env.ROOM.get(env.ROOM.idFromName(room)).fetch(request);
}

async function attest(env: Env, evidence: { [key: string]: unknown }, hash: Uint8Array): Promise<Verified> {
  if (evidence.t !== "appattest") return verifyAttestation(env, evidence, hash, null);
  const keyId = b64urlDecode(evidence.k);
  if (!keyId || keyId.length !== 32) return { ok: false, reason: "bad key id" };
  const identity = env.IDENTITY.get(env.IDENTITY.idFromName(b64urlEncode(keyId)));
  if (typeof evidence.o !== "string") return identity.authenticate(evidence, hash);
  const result = await verifyAttestation(env, evidence, hash, null);
  if (!result.ok) return result;
  return (await identity.enroll(result)) ? result : { ok: false, reason: "key already enrolled" };
}
