import { env, runDurableObjectAlarm, runInDurableObject, SELF } from "cloudflare:test";
import { describe, expect, it } from "vitest";
import { Client, authKey, helloFrame, record, roomId } from "./client";
import type { Room } from "../src/room";

async function join(
  room: string,
  key: Uint8Array,
  device: string,
  vector: { [device: string]: number } = {},
  register = false,
): Promise<Client> {
  const client = await Client.connect(room);
  client.send(await helloFrame(key, device, vector, register ? { register: key } : {}));
  return client;
}

function stub(room: string): DurableObjectStub<Room> {
  return env.ROOM.get(env.ROOM.idFromName(room));
}

describe("routing", () => {
  it("serves health and rejects everything else", async () => {
    expect((await SELF.fetch("https://relay.test/health")).status).toBe(200);
    const home = await SELF.fetch("https://relay.test/", { redirect: "manual" });
    expect(home.status).toBe(302);
    expect(home.headers.get("Location")).toBe("https://github.com/katagaki/CirclesRelay");
    expect((await SELF.fetch("https://relay.test/?x=1")).status).toBe(400);
    expect((await SELF.fetch("https://relay.test/r/nothex")).status).toBe(400);
    const upgrade = { headers: { Upgrade: "websocket" } };
    expect((await SELF.fetch(`https://relay.test/r/${roomId()}`, upgrade)).status).toBe(101);
    expect((await SELF.fetch(`https://relay.test/r/${roomId()}`)).status).toBe(400);
  });
});

describe("fan-out", () => {
  it("delivers a record to peers but not the sender", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    expect(await a.next()).toEqual({ t: "ops", o: [] });
    const b = await join(room, key, "bbbbbbbb");
    expect(await b.next()).toEqual({ t: "ops", o: [] });

    const op = await record(key, "aaaaaaaa", 1, "sealed-one");
    a.send({ t: "ops", o: [op] });

    expect(await b.next()).toEqual({ t: "ops", o: [op] });
    await a.quiet();
  });

  it("sends only the records a version vector lacks", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    const ops = [
      await record(key, "aaaaaaaa", 1, "one"),
      await record(key, "aaaaaaaa", 2, "two"),
      await record(key, "aaaaaaaa", 3, "three"),
    ];
    a.send({ t: "ops", o: ops });

    const late = await join(room, key, "cccccccc", { aaaaaaaa: 2 });
    expect(await late.next()).toEqual({ t: "ops", o: [ops[2]] });
    await late.quiet();
  });

  it("ignores a re-sent record and does not fan it out", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    const b = await join(room, key, "bbbbbbbb");
    await b.next();

    const op = await record(key, "aaaaaaaa", 7, "sealed");
    a.send({ t: "ops", o: [op] });
    expect(await b.next()).toEqual({ t: "ops", o: [op] });

    a.send({ t: "ops", o: [op] });
    await b.quiet();
  });
});

describe("authentication", () => {
  it("closes with 4004 on a bad record tag and stores nothing", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();

    const forged = await record(authKey(), "aaaaaaaa", 1, "forged");
    a.send({ t: "ops", o: [forged] });
    expect((await a.closure()).code).toBe(4004);

    const b = await join(room, key, "bbbbbbbb");
    expect(await b.next()).toEqual({ t: "ops", o: [] });
  });

  it("rejects a stale hello", async () => {
    const room = roomId();
    const key = authKey();
    const client = await Client.connect(room);
    client.send(
      await helloFrame(key, "aaaaaaaa", {}, { register: key, ts: Math.floor(Date.now() / 1000) - 301 }),
    );
    expect((await client.closure()).code).toBe(4004);
  });

  it("tells a hello for an unknown room to resend with the key", async () => {
    const room = roomId();
    const client = await Client.connect(room);
    client.send(await helloFrame(authKey(), "aaaaaaaa"));
    expect((await client.closure()).code).toBe(4006);
  });

  it("lets a client back in with its key after the room expires", async () => {
    const room = roomId();
    const key = authKey();
    const first = await join(room, key, "aaaaaaaa", {}, true);
    await first.next();
    await runInDurableObject(stub(room), async (instance: Room) => {
      await instance.alarm();
    });

    const stale = await Client.connect(room);
    stale.send(await helloFrame(key, "aaaaaaaa"));
    expect((await stale.closure()).code).toBe(4006);

    const retried = await join(room, key, "aaaaaaaa", {}, true);
    expect(await retried.next()).toEqual({ t: "ops", o: [] });
  });

  it("keeps the first registered key when a later hello offers another", async () => {
    const room = roomId();
    const key = authKey();
    const first = await join(room, key, "aaaaaaaa", {}, true);
    await first.next();

    const other = authKey();
    const intruder = await Client.connect(room);
    intruder.send(await helloFrame(other, "bbbbbbbb", {}, { register: other }));
    expect((await intruder.closure()).code).toBe(4004);

    const legitimate = await join(room, key, "cccccccc");
    expect(await legitimate.next()).toEqual({ t: "ops", o: [] });
  });
});

describe("limits", () => {
  it("closes 4002 on an oversized frame", async () => {
    const client = await Client.connect(roomId());
    client.send(JSON.stringify({ t: "hello", pad: "x".repeat(4200) }));
    expect((await client.closure()).code).toBe(4002);
  });

  it("closes 4002 on more than 32 records in a frame", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    const op = await record(key, "aaaaaaaa", 1, "x");
    a.send({ t: "ops", o: Array.from({ length: 33 }, () => op) });
    expect((await a.closure()).code).toBe(4002);
  });

  it("closes 4001 when a socket exceeds its message rate", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    for (let seq = 1; seq <= 25 && !a.closed; seq++) {
      a.send({ t: "ops", o: [await record(key, "aaaaaaaa", seq, `op-${seq}`)] });
    }
    expect((await a.closure()).code).toBe(4001);
  });

  it("closes 4003 on the ninth socket in a room", async () => {
    const room = roomId();
    const key = authKey();
    const first = await join(room, key, "aaaaaaaa", {}, true);
    await first.next();
    const rest = [];
    for (let i = 1; i < 8; i++) rest.push(await Client.connect(room));
    const overflow = await Client.connect(room);
    expect((await overflow.closure()).code).toBe(4003);
  });

  it("does not count records it already holds against the cap", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    let seq = 1;
    let first: { d: string; n: number; b: string; a: string } | null = null;
    for (let frame = 0; frame < 16; frame++) {
      const size = frame === 15 ? 20 : 32;
      const ops = [];
      for (let i = 0; i < size; i++) {
        const entry = await record(key, "aaaaaaaa", seq++, `o${seq}`);
        ops.push(entry);
        first ??= entry;
      }
      a.send({ t: "ops", o: ops });
    }
    a.send({ t: "ops", o: [first!] });

    const b = await join(room, key, "bbbbbbbb", { aaaaaaaa: 500 }, false);
    expect(await b.next()).toEqual({ t: "ops", o: [] });
    expect(a.closed).toBeNull();
  });

  it("closes 4005 once the room holds 500 records", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    let seq = 1;
    for (let frame = 0; frame < 16; frame++) {
      const size = frame === 15 ? 20 : 32;
      const ops = [];
      for (let i = 0; i < size; i++) ops.push(await record(key, "aaaaaaaa", seq++, `o${seq}`));
      a.send({ t: "ops", o: ops });
    }
    a.send({ t: "ops", o: [await record(key, "aaaaaaaa", seq, "overflow")] });
    expect((await a.closure()).code).toBe(4005);

    await runInDurableObject(stub(room), (_instance: Room, state: DurableObjectState) => {
      expect(Number(state.storage.sql.exec("SELECT COUNT(*) AS c FROM ops").one().c)).toBe(500);
    });
  });
});

describe("hibernation", () => {
  it("keeps every piece of connection state outside the instance", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    a.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "before")] });
    await new Promise((resolve) => setTimeout(resolve, 50));

    await runInDurableObject(stub(room), (instance: Room, state: DurableObjectState) => {
      expect(Object.keys(instance).filter((k) => k !== "ctx" && k !== "env" && k !== "sql")).toEqual([]);
      const sockets = state.getWebSockets();
      expect(sockets.length).toBe(1);
      expect((sockets[0].deserializeAttachment() as { d: string }).d).toBe("aaaaaaaa");
      expect(Number(state.storage.sql.exec("SELECT COUNT(*) AS c FROM room").one().c)).toBe(1);
      expect(Number(state.storage.sql.exec("SELECT COUNT(*) AS c FROM ops").one().c)).toBe(1);
    });

    const b = await join(room, key, "bbbbbbbb");
    const caught = await b.next();
    expect(caught.o.length).toBe(1);
  });

  it("answers a ping without running the message handler", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    a.ws.send("ping");
    expect(await a.nextRaw()).toBe("pong");
    expect(a.closed).toBe(null);
  });
});

describe("lifetime", () => {
  it("clears the room when the alarm fires", async () => {
    const room = roomId();
    const key = authKey();
    const a = await join(room, key, "aaaaaaaa", {}, true);
    await a.next();
    a.send({ t: "ops", o: [await record(key, "aaaaaaaa", 1, "doomed")] });
    await new Promise((resolve) => setTimeout(resolve, 50));

    expect(await runDurableObjectAlarm(stub(room))).toBe(true);
    await runInDurableObject(stub(room), (_instance: Room, state: DurableObjectState) => {
      expect(Number(state.storage.sql.exec("SELECT COUNT(*) AS c FROM ops").one().c)).toBe(0);
      expect(Number(state.storage.sql.exec("SELECT COUNT(*) AS c FROM room").one().c)).toBe(0);
    });
    expect((await a.closure()).code).toBe(1001);
  });
});
