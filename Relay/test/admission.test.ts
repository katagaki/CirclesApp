import { env, runInDurableObject } from "cloudflare:test";
import { describe, expect, it, vi } from "vitest";
import worker, { HELLO_HEADER, type Env } from "../src/index";
import { AUTHENTICATED_HEADER } from "../src/admission";
import { attestInput, b64urlEncode, sha256 } from "../src/proto";
import { assertionKeys, assertion, appIdHash } from "./attest";
import { authKey, helloFrame, roomId } from "./client";

function request(room: string, hello?: string, forged = false): Request {
  const headers = new Headers({ Upgrade: "websocket" });
  if (hello) headers.set(HELLO_HEADER, b64urlEncode(new TextEncoder().encode(hello)));
  if (forged) headers.set(AUTHENTICATED_HEADER, "1");
  return new Request(`https://relay.test/r/${room}`, { headers });
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
    const frame = JSON.parse(await helloFrame(authKey(), "aaaaaaaa"));
    for (const evidence of [undefined, {t:"unknown"}, {t:"appattest",k:"invalid",o:"invalid"}, {t:"playintegrity",tk:"invalid"}]) {
      frame.at = evidence;
      expect((await worker.fetch(request(room, JSON.stringify(frame)), guard.env)).status).toBe(401);
    }
    frame.ts = 0;
    expect((await worker.fetch(request(room, JSON.stringify(frame)), guard.env)).status).toBe(401);
    expect(guard.get).not.toHaveBeenCalled();
  });

  it("advances App Attest counters before routing and rejects replays, including concurrent ones", async () => {
    const room = roomId();
    const keys = await assertionKeys();
    const keyId = new Uint8Array(32).fill(42);
    const identity = env.IDENTITY.get(env.IDENTITY.idFromName(b64urlEncode(keyId)));
    await identity.enroll({ok:true,kind:"appattest",keyId,pubkey:keys.publicKey,counter:0});
    const frame = JSON.parse(await helloFrame(authKey(), "aaaaaaaa"));
    frame.at = {t:"appattest",k:b64urlEncode(keyId),s:await assertion(keys, await appIdHash("YYM4Z6MU8F","com.tsubuzaki.CiRCLES"),1,await sha256(attestInput(frame.d,frame.ts,room)))};
    const fetch = vi.fn(async () => new Response("authenticated"));
    const guardedEnv = {...env,ROOM:{idFromName:vi.fn(),get:vi.fn(()=>({fetch}))},ATTEST_MODE:"required"} as unknown as Env;
    const results = await Promise.all([worker.fetch(request(room,JSON.stringify(frame)),guardedEnv),worker.fetch(request(room,JSON.stringify(frame)),guardedEnv)]);
    expect(results.map(r=>r.status).sort()).toEqual([200,401]);
    expect(fetch).toHaveBeenCalledTimes(1);
    const wrongRoom = await worker.fetch(request(roomId(),JSON.stringify(frame)),guardedEnv);
    expect(wrongRoom.status).toBe(401);
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
    const frame = JSON.parse(await helloFrame(key, "aaaaaaaa", {}, {register:key}));
    frame.at = {t:"appattest",k:b64urlEncode(keyId),s:await assertion(keys,await appIdHash("YYM4Z6MU8F","com.tsubuzaki.CiRCLES"),1,await sha256(attestInput(frame.d,frame.ts,room)))};
    const response = await worker.fetch(request(room, JSON.stringify(frame)), {...env} as Env);
    expect(response.status).toBe(101);
    const socket = response.webSocket!;
    socket.accept();
    await runInDurableObject(env.ROOM.get(env.ROOM.idFromName(room)), (_instance,state) => {
      expect(state.getWebSockets().length).toBe(1);
      expect(state.getWebSockets()[0].deserializeAttachment().d).toBe("aaaaaaaa");
      expect(state.storage.sql.exec("SELECT device FROM devices").toArray()).toEqual([{device:"aaaaaaaa"}]);
    });
    const replay = await worker.fetch(request(room,JSON.stringify(frame)), {...env} as Env);
    expect(replay.status).toBe(401);
    expect(replay.webSocket).toBeNull();
    socket.close();
  });

});
