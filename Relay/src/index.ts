import { AUTHENTICATED_HEADER, readHello, rejection } from "./admission";
import { Room, HELLO_SKEW_SECONDS } from "./room";
import { Identity } from "./identity";
import type { PushEnv } from "./push";
import { type AttestEnv, attestMode, isLoopback, verifyAttestation } from "./attest";
import { attestInput, b64urlDecode, b64urlEncode, sha256 } from "./proto";

export { Room, Identity };
export { HELLO_HEADER } from "./admission";

const ROOM_PATH = /^\/r\/([0-9a-f]{32})$/;
const HOMEPAGE = "https://github.com/katagaki/CirclesRelay";

export interface Env extends PushEnv, AttestEnv {
  ROOM: DurableObjectNamespace<Room>;
  IDENTITY: DurableObjectNamespace<Identity>;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health") return new Response("ok");
    if (url.pathname === "/" && url.search === "") return Response.redirect(HOMEPAGE, 302);
    const match = ROOM_PATH.exec(url.pathname);
    if (!match) return new Response("bad request", { status: 400 });
    if (request.method !== "GET" || request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("expected websocket", { status: 400 });
    }
    const frame = readHello(request);
    if (!frame) return rejection(401, "auth", "authenticated hello required");
    if (typeof frame.d !== "string" || !/^[0-9a-f]{8}$/.test(frame.d)) return rejection(400, "proto", "bad device id");
    if (!Number.isSafeInteger(frame.ts) || (frame.ts as number) < 0) return rejection(400, "proto", "bad timestamp");
    if (Math.abs(Math.floor(Date.now() / 1000) - (frame.ts as number)) > HELLO_SKEW_SECONDS) return rejection(401, "auth", "stale hello");
    const mode = attestMode(env, isLoopback(url.hostname));
    const evidence = frame.at as { t?: unknown; k?: unknown; o?: unknown; s?: unknown } | undefined;
    if (mode !== "off" && (evidence != null || mode === "required")) {
      if (!evidence || typeof evidence !== "object") return rejection(401, "auth", "attestation required");
      const hash = await sha256(attestInput(frame.d, frame.ts as number, match[1]));
      if (evidence.t === "appattest") {
        const keyId = b64urlDecode(evidence.k);
        if (!keyId || keyId.length !== 32) return rejection(401, "auth", "bad key id");
        if (typeof evidence.o === "string") {
          const result = await verifyAttestation(env, evidence, hash, null);
          if (!result.ok) return rejection(401, "auth", result.reason);
          if (!(await env.IDENTITY.get(env.IDENTITY.idFromName(b64urlEncode(keyId))).enroll(result))) {
            return rejection(401, "auth", "key already enrolled");
          }
        } else {
          const result = await env.IDENTITY.get(env.IDENTITY.idFromName(b64urlEncode(keyId))).authenticate(evidence, hash);
          if (!result.ok) return rejection(401, "auth", result.reason);
        }
      } else {
        const result = await verifyAttestation(env, evidence, hash, null);
        if (!result.ok) return rejection(401, "auth", result.reason);
      }
    }
    const forwarded = new Request(request);
    forwarded.headers.set(AUTHENTICATED_HEADER, "1");
    return env.ROOM.get(env.ROOM.idFromName(match[1])).fetch(forwarded);
  },
};
