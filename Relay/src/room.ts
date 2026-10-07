import { DurableObject } from "cloudflare:workers";
import { type Environment, type Platform, type PushEnv, type Target, push } from "./push";
import type { AttestEnv } from "./attest";
import { AUTHENTICATED_HEADER, readHello, rejection } from "./admission";
import {
  TAG_LEN,
  b64urlDecode,
  b64urlEncode,
  helloInput,
  importAuthKey,
  recordInput,
  tag,
  timingSafeEqual,
  toBytes,
} from "./proto";

export const MAX_FRAME_BYTES = 4096;
export const MAX_RECORDS_PER_FRAME = 32;
export const RATE_TOKENS = 20;
export const RATE_WINDOW_MS = 10_000;
export const MAX_SOCKETS = 8;
export const MAX_STORED_RECORDS = 500;
export const HELLO_SKEW_SECONDS = 300;
export const ROOM_TTL_MS = 48 * 60 * 60 * 1000;
export const PUSH_COALESCE_MS = 10_000;
export const MAX_TOKEN_LENGTH = 512;

export const CLOSE_RATE = 4001;
export const CLOSE_PROTOCOL = 4002;
export const CLOSE_ROOM_FULL = 4003;
export const CLOSE_AUTH = 4004;
export const CLOSE_STORAGE_FULL = 4005;
export const CLOSE_UNKNOWN_ROOM = 4006;
export const CLOSE_REPLACED = 4007;

const DEVICE_ID = /^[0-9a-f]{8}$/;
const PUSH_TOKEN = /^[A-Za-z0-9_:.-]{1,512}$/;

interface Attachment {
  d: string | null;
  tk: number;
  at: number;
}

interface Record {
  d: string;
  n: number;
  b: string;
  a: string;
}

class Fail extends Error {
  constructor(readonly code: number, message: string) {
    super(message);
  }
}

const SLUG: { [code: number]: string } = {
  [CLOSE_RATE]: "rate",
  [CLOSE_PROTOCOL]: "proto",
  [CLOSE_ROOM_FULL]: "full",
  [CLOSE_AUTH]: "auth",
  [CLOSE_STORAGE_FULL]: "storage",
  [CLOSE_UNKNOWN_ROOM]: "unknown",
  [CLOSE_REPLACED]: "replaced",
};

function byteLength(text: string): number {
  return new TextEncoder().encode(text).byteLength;
}

function isSeq(value: unknown): value is number {
  return typeof value === "number" && Number.isSafeInteger(value) && value >= 0;
}

function isPositiveSeq(value: unknown): value is number {
  return isSeq(value) && value > 0;
}

export class Room extends DurableObject<PushEnv & AttestEnv> {
  private sql: SqlStorage;

  constructor(ctx: DurableObjectState, env: PushEnv & AttestEnv) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.sql.exec(`CREATE TABLE IF NOT EXISTS ops (
      device TEXT    NOT NULL,
      seq    INTEGER NOT NULL,
      blob   BLOB    NOT NULL,
      tag    BLOB    NOT NULL,
      ts     INTEGER NOT NULL,
      PRIMARY KEY (device, seq)
    )`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS room (
      id         INTEGER PRIMARY KEY CHECK (id = 1),
      auth_key   BLOB    NOT NULL,
      created_at INTEGER NOT NULL
    )`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS tokens (
      device   TEXT    PRIMARY KEY,
      platform TEXT    NOT NULL,
      token    TEXT    NOT NULL,
      env      TEXT    NOT NULL,
      pushed   INTEGER NOT NULL
    )`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS devices (
      device   TEXT PRIMARY KEY,
      auth_key BLOB NOT NULL
    )`);
    for (const socket of ctx.getWebSockets()) {
      if (!(socket.deserializeAttachment() as Attachment | null)?.d) this.reject(socket, CLOSE_AUTH, "authentication required");
    }
    ctx.setWebSocketAutoResponse(new WebSocketRequestResponsePair("ping", "pong"));
  }

  override async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("expected websocket", { status: 400 });
    }
    if (request.headers.get(AUTHENTICATED_HEADER) !== "1") return rejection(401, "auth", "attestation required");
    const frame = readHello(request);
    if (!frame) return rejection(401, "auth", "authenticated hello required");
    return this.ctx.blockConcurrencyWhile(async () => {
      try {
        const device = await this.authorize(frame);
        const pair = new WebSocketPair();
        const client = pair[0];
        const server = pair[1];
        this.admit(server, device);
        this.ctx.acceptWebSocket(server);
        server.serializeAttachment({ d: device, tk: RATE_TOKENS, at: Date.now() } satisfies Attachment);
        server.send(JSON.stringify({ t: "held", n: this.heldPrefix(device) }));
        this.send(server, this.missing(frame.v));
        return new Response(null, { status: 101, webSocket: client });
      } catch (error) {
        if (!(error instanceof Fail)) throw error;
        const status = error.code === CLOSE_AUTH ? 401 : error.code === CLOSE_UNKNOWN_ROOM ? 404 : error.code === CLOSE_ROOM_FULL ? 429 : 400;
        return rejection(status, SLUG[error.code], error.message);
      }
    });
  }

  override async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer): Promise<void> {
    try {
      await this.dispatch(ws, message);
    } catch (error) {
      if (error instanceof Fail) {
        this.reject(ws, error.code, error.message);
        return;
      }
      console.log("relay: unhandled error");
      this.reject(ws, CLOSE_PROTOCOL, "internal error");
    }
  }

  override async alarm(): Promise<void> {
    this.sql.exec("DELETE FROM ops");
    this.sql.exec("DELETE FROM room");
    this.sql.exec("DELETE FROM tokens");
    this.sql.exec("DELETE FROM devices");
    for (const ws of this.ctx.getWebSockets()) ws.close(1001, "room expired");
  }

  private async dispatch(ws: WebSocket, message: string | ArrayBuffer): Promise<void> {
    if (typeof message !== "string") throw new Fail(CLOSE_PROTOCOL, "text frames only");
    const size = byteLength(message);
    if (size > MAX_FRAME_BYTES) throw new Fail(CLOSE_PROTOCOL, "frame too large");

    const attachment = this.spend(ws);
    let frame: Record | { t?: unknown } | null;
    try {
      frame = JSON.parse(message);
    } catch {
      throw new Fail(CLOSE_PROTOCOL, "malformed frame");
    }
    if (!frame || typeof frame !== "object") throw new Fail(CLOSE_PROTOCOL, "malformed frame");

    const type = (frame as { t?: unknown }).t;
    if (type === "ops") await this.onOps(ws, frame as never, attachment);
    else if (type === "bye") ws.close(1000, "bye");
    else throw new Fail(CLOSE_PROTOCOL, "unknown frame type");
  }

  private spend(ws: WebSocket): Attachment {
    const attachment = (ws.deserializeAttachment() ?? { d: null, tk: RATE_TOKENS, at: Date.now() }) as Attachment;
    const now = Date.now();
    const refill = ((now - attachment.at) / RATE_WINDOW_MS) * RATE_TOKENS;
    attachment.tk = Math.min(RATE_TOKENS, attachment.tk + refill);
    attachment.at = now;
    if (attachment.tk < 1) throw new Fail(CLOSE_RATE, "too many messages");
    attachment.tk -= 1;
    ws.serializeAttachment(attachment);
    return attachment;
  }

  private async authorize(frame: { [key: string]: unknown }): Promise<string> {
    const device = frame.d;
    if (typeof device !== "string" || !DEVICE_ID.test(device)) throw new Fail(CLOSE_PROTOCOL, "bad device id");
    if (!isSeq(frame.ts)) throw new Fail(CLOSE_PROTOCOL, "bad timestamp");
    if (Math.abs(Math.floor(Date.now() / 1000) - frame.ts) > HELLO_SKEW_SECONDS) {
      throw new Fail(CLOSE_AUTH, "stale hello");
    }
    const offered = b64urlDecode(frame.a);
    if (!offered || offered.length !== TAG_LEN) throw new Fail(CLOSE_AUTH, "bad tag");

    const existing = this.authKey();
    let keyBytes = existing;
    if (!keyBytes) {
      const registered = b64urlDecode(frame.k);
      if (!registered || registered.length !== 32) {
        throw new Fail(CLOSE_UNKNOWN_ROOM, "room not found, resend hello with the key");
      }
      keyBytes = registered;
    }
    const key = await importAuthKey(keyBytes);
    const expected = await tag(key, helloInput(device, frame.ts));
    if (!timingSafeEqual(expected, offered)) throw new Fail(CLOSE_AUTH, "bad tag");

    const registeredDeviceKey = this.deviceKey(device);
    const suppliedDeviceKey = b64urlDecode(frame.x);
    const deviceKeyBytes = registeredDeviceKey ?? suppliedDeviceKey;
    if (!deviceKeyBytes || deviceKeyBytes.length !== 32) throw new Fail(CLOSE_AUTH, "device key required");
    const deviceOffered = b64urlDecode(frame.da);
    if (!deviceOffered || deviceOffered.length !== TAG_LEN) throw new Fail(CLOSE_AUTH, "bad device tag");
    const deviceExpected = await tag(await importAuthKey(deviceKeyBytes), helloInput(device, frame.ts));
    if (!timingSafeEqual(deviceExpected, deviceOffered)) throw new Fail(CLOSE_AUTH, "bad device tag");

    if (!existing) {
      this.sql.exec(
        "INSERT INTO room (id, auth_key, created_at) VALUES (1, ?, ?)",
        keyBytes,
        Math.floor(Date.now() / 1000),
      );
      await this.ctx.storage.setAlarm(Date.now() + ROOM_TTL_MS);
    }
    if (!registeredDeviceKey) {
      this.sql.exec("INSERT INTO devices (device, auth_key) VALUES (?, ?)", device, deviceKeyBytes);
    }

    this.register(device, frame.p);
    return device;
  }

  private async onOps(
    ws: WebSocket,
    frame: { o?: unknown },
    attachment: Attachment,
  ): Promise<void> {
    if (!attachment.d) throw new Fail(CLOSE_PROTOCOL, "hello required");
    const list = frame.o;
    if (!Array.isArray(list) || list.length === 0) throw new Fail(CLOSE_PROTOCOL, "no records");
    if (list.length > MAX_RECORDS_PER_FRAME) throw new Fail(CLOSE_PROTOCOL, "too many records");
    const keyBytes = this.authKey();
    if (!keyBytes) throw new Fail(CLOSE_UNKNOWN_ROOM, "room not found, resend hello with the key");
    const key = await importAuthKey(keyBytes);

    const records: { record: Record; blob: Uint8Array; tag: Uint8Array }[] = [];
    for (const entry of list) {
      if (!entry || typeof entry !== "object") throw new Fail(CLOSE_PROTOCOL, "bad record");
      const { d, n, b, a } = entry as Record;
      if (typeof d !== "string" || !DEVICE_ID.test(d)) throw new Fail(CLOSE_PROTOCOL, "bad device id");
      if (d !== attachment.d) throw new Fail(CLOSE_AUTH, "device mismatch");
      if (!isPositiveSeq(n)) throw new Fail(CLOSE_PROTOCOL, "bad seq");
      const blob = b64urlDecode(b);
      const offered = b64urlDecode(a);
      if (!blob || blob.length === 0) throw new Fail(CLOSE_PROTOCOL, "bad blob");
      if (!offered || offered.length !== TAG_LEN) throw new Fail(CLOSE_AUTH, "bad tag");
      const expected = await tag(key, recordInput(d, n, blob));
      if (!timingSafeEqual(expected, offered)) throw new Fail(CLOSE_AUTH, "bad tag");
      records.push({ record: { d, n, b, a }, blob, tag: offered });
    }

    const pending = new Set<string>();
    for (const { record } of records) {
      const id = `${record.d}:${record.n}`;
      if (pending.has(id) || this.holds(record.d, record.n)) continue;
      pending.add(id);
    }
    if (this.count() + pending.size > MAX_STORED_RECORDS) {
      throw new Fail(CLOSE_STORAGE_FULL, "room is full");
    }

    const now = Math.floor(Date.now() / 1000);
    const fresh: Record[] = [];
    for (const { record, blob, tag: mac } of records) {
      const written = this.sql.exec(
        "INSERT OR IGNORE INTO ops (device, seq, blob, tag, ts) VALUES (?, ?, ?, ?, ?)",
        record.d,
        record.n,
        blob,
        mac,
        now,
      ).rowsWritten;
      if (written > 0) fresh.push(record);
    }
    if (fresh.length === 0) return;

    await this.ctx.storage.setAlarm(Date.now() + ROOM_TTL_MS);
    const connected = new Set<string>();
    for (const peer of this.ctx.getWebSockets()) {
      const peerAttachment = peer.deserializeAttachment() as Attachment | null;
      if (!peerAttachment?.d) continue;
      connected.add(peerAttachment.d);
      if (peer === ws) continue;
      this.send(peer, fresh);
    }
    this.wake(connected);
  }

  private admit(ws: WebSocket, device: string): void {
    let members = 0;
    for (const peer of this.ctx.getWebSockets()) {
      if (peer === ws || peer.readyState !== WebSocket.OPEN) continue;
      const attachment = peer.deserializeAttachment() as Attachment | null;
      if (!attachment?.d) continue;
      if (attachment.d === device) {
        this.reject(peer, CLOSE_REPLACED, "replaced by a newer connection");
        continue;
      }
      members++;
    }
    if (members >= MAX_SOCKETS) throw new Fail(CLOSE_ROOM_FULL, "room is full");
  }

  private register(device: string, value: unknown): void {
    if (value === undefined || value === null) return;
    if (typeof value !== "object") throw new Fail(CLOSE_PROTOCOL, "bad push registration");
    const { pl, tk, e } = value as { pl?: unknown; tk?: unknown; e?: unknown };
    if (pl !== "apns" && pl !== "fcm") throw new Fail(CLOSE_PROTOCOL, "bad push platform");
    if (typeof tk !== "string" || !PUSH_TOKEN.test(tk)) throw new Fail(CLOSE_PROTOCOL, "bad push token");
    if (e !== undefined && e !== "sandbox" && e !== "production") {
      throw new Fail(CLOSE_PROTOCOL, "bad push environment");
    }
    this.sql.exec(
      `INSERT INTO tokens (device, platform, token, env, pushed) VALUES (?, ?, ?, ?, 0)
       ON CONFLICT (device) DO UPDATE SET platform = excluded.platform, token = excluded.token, env = excluded.env`,
      device,
      pl,
      tk,
      e ?? "sandbox",
    );
  }

  private wake(connected: Set<string>): void {
    const now = Date.now();
    const targets: (Target & { device: string })[] = [];
    for (const row of this.sql.exec("SELECT device, platform, token, env, pushed FROM tokens").toArray()) {
      const device = row.device as string;
      if (connected.has(device)) continue;
      if (now - Number(row.pushed) < PUSH_COALESCE_MS) continue;
      targets.push({
        device,
        platform: row.platform as Platform,
        token: row.token as string,
        environment: row.env as Environment,
      });
    }
    if (targets.length === 0) return;
    for (const target of targets) {
      this.sql.exec("UPDATE tokens SET pushed = ? WHERE device = ?", now, target.device);
    }
    this.ctx.waitUntil(this.deliver(targets));
  }

  private async deliver(targets: (Target & { device: string })[]): Promise<void> {
    for (const target of targets) {
      const outcome = await push(this.env, target);
      if (outcome === "gone") this.sql.exec("DELETE FROM tokens WHERE device = ?", target.device);
    }
  }

  private authKey(): Uint8Array | null {
    const row = this.sql.exec("SELECT auth_key FROM room WHERE id = 1").toArray()[0];
    return row ? toBytes(row.auth_key as ArrayBuffer) : null;
  }

  private deviceKey(device: string): Uint8Array | null {
    const row = this.sql.exec("SELECT auth_key FROM devices WHERE device = ?", device).toArray()[0];
    return row ? toBytes(row.auth_key as ArrayBuffer) : null;
  }

  private holds(device: string, seq: number): boolean {
    return this.sql.exec("SELECT 1 FROM ops WHERE device = ? AND seq = ? LIMIT 1", device, seq).toArray().length > 0;
  }

  private heldPrefix(device: string): number {
    let next = 1;
    for (const row of this.sql.exec("SELECT seq FROM ops WHERE device = ? ORDER BY seq", device)) {
      const seq = Number(row.seq);
      if (seq > next) break;
      if (seq === next) next++;
    }
    return next - 1;
  }

  private count(): number {
    return Number(this.sql.exec("SELECT COUNT(*) AS c FROM ops").one().c);
  }

  private missing(vector: unknown): Record[] {
    const held = (vector && typeof vector === "object" ? vector : {}) as { [device: string]: unknown };
    const rows = this.sql
      .exec("SELECT device, seq, blob, tag FROM ops ORDER BY device, seq LIMIT ?", MAX_STORED_RECORDS)
      .toArray();
    const out: Record[] = [];
    for (const row of rows) {
      const device = row.device as string;
      const seq = Number(row.seq);
      const seen = held[device];
      if (isSeq(seen) && seq <= seen) continue;
      out.push({
        d: device,
        n: seq,
        b: b64urlEncode(toBytes(row.blob as ArrayBuffer)),
        a: b64urlEncode(toBytes(row.tag as ArrayBuffer)),
      });
    }
    return out;
  }

  private send(ws: WebSocket, records: Record[]): void {
    for (const frame of chunk(records)) {
      try {
        ws.send(JSON.stringify({ t: "ops", o: frame }));
      } catch {
        return;
      }
    }
  }

  private reject(ws: WebSocket, code: number, message: string): void {
    const slug = SLUG[code] ?? "error";
    try {
      ws.send(JSON.stringify({ t: "err", c: slug, m: message }));
      ws.close(code, slug);
    } catch {
      /* socket already gone */
    }
  }
}

function chunk(records: Record[]): Record[][] {
  if (records.length === 0) return [[]];
  const frames: Record[][] = [];
  let current: Record[] = [];
  let size = 16;
  for (const record of records) {
    const cost = JSON.stringify(record).length + 1;
    if (current.length > 0 && size + cost > MAX_FRAME_BYTES) {
      frames.push(current);
      current = [];
      size = 16;
    }
    current.push(record);
    size += cost;
  }
  frames.push(current);
  return frames;
}
