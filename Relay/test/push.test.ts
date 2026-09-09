import { env, runInDurableObject } from "cloudflare:test";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { Client, authKey, helloFrame, record, roomId } from "./client";
import { resetBearers } from "../src/push";
import type { Room } from "../src/room";

interface Seen {
  url: string;
  headers: { [key: string]: string };
  body: string;
}

let apnsStatus = 200;
let seen: Seen[] = [];
const real = globalThis.fetch;

function stub(url: string, init: RequestInit | undefined): Response {
  const headers: { [key: string]: string } = {};
  for (const [name, value] of Object.entries((init?.headers ?? {}) as Record<string, string>)) {
    headers[name.toLowerCase()] = value;
  }
  seen.push({ url, headers, body: String(init?.body ?? "") });
  if (url.includes("oauth2.googleapis.com")) {
    return Response.json({ access_token: "test-access-token", expires_in: 3599 });
  }
  if (url.includes("fcm.googleapis.com")) {
    return Response.json({ name: "projects/circles-test/messages/1" });
  }
  return new Response("", { status: apnsStatus });
}

async function settled(count: number): Promise<Seen[]> {
  for (let attempt = 0; attempt < 30; attempt++) {
    if (seen.length >= count) break;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  await new Promise((resolve) => setTimeout(resolve, 100));
  return seen;
}

async function tokenCount(room: string): Promise<number> {
  const target = env.ROOM.get(env.ROOM.idFromName(room));
  return runInDurableObject(target, (instance: Room) =>
    Number((instance as never as { sql: SqlStorage }).sql.exec("SELECT COUNT(*) AS c FROM tokens").one().c),
  );
}

beforeAll(() => {
  vi.stubGlobal("fetch", (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    if (!url.startsWith("https://api.sandbox.push.apple.com") && !url.includes("googleapis.com")) {
      return real(input as never, init as never);
    }
    return Promise.resolve(stub(url, init));
  });
});

afterAll(() => {
  vi.unstubAllGlobals();
});

beforeEach(() => {
  seen = [];
  apnsStatus = 200;
  resetBearers();
});

describe("push", () => {
  it("wakes a registered device that is not connected", async () => {
    const room = roomId();
    const key = authKey();
    const push = { pl: "apns", tk: "aabbccdd11223344", e: "sandbox" };

    const away = await Client.connect(room);
    away.send(await helloFrame(key, "bbbbbbbb", {}, { register: key, push }));
    await away.next();
    away.send({ t: "bye" });
    await away.closure();

    const writer = await Client.connect(room);
    writer.send(await helloFrame(key, "aaaaaaaa"));
    await writer.next();
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "sealed")] });

    const calls = await settled(1);
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe("https://api.sandbox.push.apple.com/3/device/aabbccdd11223344");
    expect(calls[0].headers["apns-push-type"]).toBe("background");
    expect(calls[0].headers["apns-topic"]).toBe("com.tsubuzaki.CiRCLES");
    expect(calls[0].headers.authorization).toMatch(/^bearer eyJ/);
    expect(JSON.parse(calls[0].body)).toEqual({ aps: { "content-available": 1 } });
  });

  it("does not wake a device that is connected, or the writer", async () => {
    const room = roomId();
    const key = authKey();
    const push = { pl: "apns", tk: "deadbeefdeadbeef", e: "sandbox" };

    const listener = await Client.connect(room);
    listener.send(await helloFrame(key, "bbbbbbbb", {}, { register: key, push }));
    await listener.next();

    const writer = await Client.connect(room);
    writer.send(await helloFrame(key, "aaaaaaaa", {}, { push: { pl: "apns", tk: "cafecafecafecafe" } }));
    await writer.next();
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "sealed")] });

    await listener.next();
    await new Promise((resolve) => setTimeout(resolve, 200));
    expect(seen).toHaveLength(0);
  });

  it("coalesces bursts into one push", async () => {
    const room = roomId();
    const key = authKey();

    const away = await Client.connect(room);
    away.send(await helloFrame(key, "bbbbbbbb", {}, { register: key, push: { pl: "apns", tk: "0011223344556677" } }));
    await away.next();
    away.send({ t: "bye" });
    await away.closure();

    const writer = await Client.connect(room);
    writer.send(await helloFrame(key, "aaaaaaaa"));
    await writer.next();
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "one")] });
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 2, "two")] });
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 3, "three")] });

    await settled(1);
    await new Promise((resolve) => setTimeout(resolve, 200));
    expect(seen).toHaveLength(1);
  });

  it("sends a data-only high priority message over FCM", async () => {
    const room = roomId();
    const key = authKey();

    const away = await Client.connect(room);
    away.send(await helloFrame(key, "bbbbbbbb", {}, { register: key, push: { pl: "fcm", tk: "fcm:token-1_x" } }));
    await away.next();
    away.send({ t: "bye" });
    await away.closure();

    const writer = await Client.connect(room);
    writer.send(await helloFrame(key, "aaaaaaaa"));
    await writer.next();
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "sealed")] });

    const calls = await settled(2);
    expect(calls).toHaveLength(2);
    expect(calls[0].url).toBe("https://oauth2.googleapis.com/token");
    expect(calls[1].url).toBe("https://fcm.googleapis.com/v1/projects/circles-test/messages:send");
    expect(calls[1].headers.authorization).toBe("Bearer test-access-token");
    expect(JSON.parse(calls[1].body)).toEqual({
      message: { token: "fcm:token-1_x", data: { t: "sync" }, android: { priority: "HIGH" } },
    });
  });

  it("forgets a token APNs reports as gone", async () => {
    const room = roomId();
    const key = authKey();
    apnsStatus = 410;

    const away = await Client.connect(room);
    away.send(await helloFrame(key, "bbbbbbbb", {}, { register: key, push: { pl: "apns", tk: "8899aabbccddeeff" } }));
    await away.next();
    away.send({ t: "bye" });
    await away.closure();

    expect(await tokenCount(room)).toBe(1);

    const writer = await Client.connect(room);
    writer.send(await helloFrame(key, "aaaaaaaa"));
    await writer.next();
    writer.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "sealed")] });

    await settled(1);
    await new Promise((resolve) => setTimeout(resolve, 200));
    expect(await tokenCount(room)).toBe(0);
  });

  it("rejects a malformed registration", async () => {
    const room = roomId();
    const key = authKey();
    const client = await Client.connect(room);
    client.send(await helloFrame(key, "aaaaaaaa", {}, { register: key, push: { pl: "sms", tk: "nope" } }));
    expect((await client.closure()).code).toBe(4002);
  });
});
