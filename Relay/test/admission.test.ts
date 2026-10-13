import { env, runInDurableObject } from "cloudflare:test";
import { describe, expect, it, vi } from "vitest";
import worker, { ATTEST_HEADER, HELLO_HEADER, type Env } from "../src/index";
import { AUTHENTICATED_HEADER } from "../src/admission";
import { attestInput, b64urlEncode, sha256 } from "../src/proto";
import { assertionKeys, assertion, appIdHash } from "./attest";
import { authKey, encodeJson, helloFrame, roomId } from "./client";

function request(room: string, hello?: string, forged = false, evidence?: unknown): Request {
  const headers = new Headers({ Upgrade: "websocket" });
  if (hello) headers.set(HELLO_HEADER, b64urlEncode(new TextEncoder().encode(hello)));
  if (evidence !== undefined) headers.set(ATTEST_HEADER, encodeJson(evidence));
  if (forged) headers.set(AUTHENTICATED_HEADER, "1");
  return new Request(`https://relay.test/r/${room}`, { headers });
}

function bound(room: string, hello: string): Promise<Uint8Array> {
  return sha256(attestInput(room, new TextEncoder().encode(hello)));
}

function guarded() {
  const get = vi.fn(() => { throw new Error("unauthenticated room access"); });
  return { get, env: { ...env, ROOM: { idFromName: vi.fn(), get }, ATTEST_MODE: "required" } as unknown as Env };
}

describe("upgrade admission", () => {
  it("rejects absent or malformed hellos and ignores forged authentication markers before room access", async () => {
    const guard = guarded();
    for (const hello of [undefined, "null", "{}", '{"t":"hello"}', "x".repeat(17000)]) {
      expect((await worker.fetch(request(roomId(), hello, true), guard.env)).status).toBeGreaterThanOrEqual(400);
    }
    expect(guard.get).not.toHaveBeenCalled();
  });

  it("rejects missing, invalid and stale attestation without creating rooms", async () => {
    const guard = guarded();
    const room = roomId();
    const hello = await helloFrame(authKey(), "aaaaaaaa");
    for (const evidence of [undefined, null, [], {t:"unknown"}, {t:"appattest",k:"invalid",o:"invalid"}, {t:"playintegrity",tk:"invalid"}]) {
      expect((await worker.fetch(request(room, hello, false, evidence), guard.env)).status).toBe(403);
    }
    const garbled = request(room, hello);
    garbled.headers.set(ATTEST_HEADER, "!!!");
    expect((await worker.fetch(garbled, guard.env)).status).toBe(403);
    const stale = JSON.stringify({...JSON.parse(hello), ts:0});
    expect((await worker.fetch(request(room, stale, false, {t:"playintegrity",tk:"invalid"}), guard.env)).status).toBe(401);
    expect(guard.get).not.toHaveBeenCalled();
  });

  it("rate limits attestation before verifying it or touching a room", async () => {
    const guard = guarded();
    const limit = vi.fn(async () => ({ success: false }));
    const limited = {...guard.env, ATTEST_LIMITER:{limit}, IDENTITY:{idFromName:vi.fn(),get:vi.fn(()=>{ throw new Error("identity access"); })}} as unknown as Env;
    const forwarded = request(roomId(), await helloFrame(authKey(), "aaaaaaaa"), false, {t:"appattest",k:b64urlEncode(new Uint8Array(32)),s:"x"});
    forwarded.headers.set("CF-Connecting-IP", "203.0.113.7");
    const response = await worker.fetch(forwarded, limited);
    expect(response.status).toBe(429);
    expect(limit).toHaveBeenCalledWith({ key: "203.0.113.7" });
    expect(guard.get).not.toHaveBeenCalled();
  });

  it("advances App Attest counters before routing and rejects replays, including concurrent ones", async () => {
    const room = roomId();
    const keys = await assertionKeys();
    const keyId = new Uint8Array(32).fill(42);
    const identity = env.IDENTITY.get(env.IDENTITY.idFromName(b64urlEncode(keyId)));
    await identity.enroll({ok:true,kind:"appattest",keyId,pubkey:keys.publicKey,counter:0});
    const hello = await helloFrame(authKey(), "aaaaaaaa");
    const evidence = {t:"appattest",k:b64urlEncode(keyId),s:await assertion(keys, await appIdHash("YYM4Z6MU8F","com.tsubuzaki.CiRCLES"),1,await bound(room, hello))};
    const fetch = vi.fn(async () => new Response("authenticated"));
    const guardedEnv = {...env,ROOM:{idFromName:vi.fn(),get:vi.fn(()=>({fetch}))},ATTEST_MODE:"required"} as unknown as Env;
    const results = await Promise.all([worker.fetch(request(room,hello,false,evidence),guardedEnv),worker.fetch(request(room,hello,false,evidence),guardedEnv)]);
    expect(results.map(r=>r.status).sort()).toEqual([200,403]);
    expect(fetch).toHaveBeenCalledTimes(1);
    const wrongRoom = await worker.fetch(request(roomId(),hello,false,evidence),guardedEnv);
    expect(wrongRoom.status).toBe(403);
    await runInDurableObject(identity, (_instance,state) => {
      expect(state.storage.sql.exec("SELECT name FROM sqlite_master WHERE type = 'table'").toArray().every(row=>row.name !== "room")).toBe(true);
    });
  });

  it("opens an authenticated production socket and leaves no pending sockets", async () => {
    const room = roomId();
    const key = authKey();
    const keys = await assertionKeys();
    const keyId = crypto.getRandomValues(new Uint8Array(32));
    const identity = env.IDENTITY.get(env.IDENTITY.idFromName(b64urlEncode(keyId)));
    const enrolled = {ok:true as const,kind:"appattest" as const,keyId,pubkey:keys.publicKey,counter:0};
    expect(await identity.enroll(enrolled)).toBe(true);
    expect(await identity.enroll(enrolled)).toBe(false);
    const hello = await helloFrame(key, "aaaaaaaa", {}, {register:key});
    const evidence = {t:"appattest",k:b64urlEncode(keyId),s:await assertion(keys,await appIdHash("YYM4Z6MU8F","com.tsubuzaki.CiRCLES"),1,await bound(room, hello))};
    const response = await worker.fetch(request(room, hello, false, evidence), {...env} as Env);
    expect(response.status).toBe(101);
    const socket = response.webSocket!;
    socket.accept();
    await runInDurableObject(env.ROOM.get(env.ROOM.idFromName(room)), (_instance,state) => {
      expect(state.getWebSockets().length).toBe(1);
      expect(state.getWebSockets()[0].deserializeAttachment().d).toBe("aaaaaaaa");
      expect(state.storage.sql.exec("SELECT device FROM devices").toArray()).toEqual([{device:"aaaaaaaa"}]);
    });
    const replay = await worker.fetch(request(room,hello,false,evidence), {...env} as Env);
    expect(replay.status).toBe(403);
    expect(replay.webSocket).toBeNull();
    socket.close();
  });

});
