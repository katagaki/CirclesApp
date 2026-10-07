import { env } from "cloudflare:test";
import worker, { HELLO_HEADER, type Env } from "../src/index";
import { b64urlEncode, helloInput, importAuthKey, recordInput, tag } from "../src/proto";

export interface CloseInfo {
  code: number;
  reason: string;
}

const deviceKeys = new Map<string, Uint8Array>();

export function roomId(): string {
  return [...crypto.getRandomValues(new Uint8Array(16))]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function authKey(): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(32));
}

export async function helloFrame(
  key: Uint8Array,
  device: string,
  vector: { [device: string]: number } = {},
  options: { register?: Uint8Array; ts?: number; push?: unknown; deviceKey?: Uint8Array } = {},
): Promise<string> {
  const ts = options.ts ?? Math.floor(Date.now() / 1000);
  const mac = await tag(await importAuthKey(key), helloInput(device, ts));
  const deviceKey = options.deviceKey ?? deviceKeys.get(device) ?? crypto.getRandomValues(new Uint8Array(32));
  deviceKeys.set(device, deviceKey);
  const deviceMac = await tag(await importAuthKey(deviceKey), helloInput(device, ts));
  const frame: { [k: string]: unknown } = {
    t: "hello", d: device, v: vector, ts, a: b64urlEncode(mac),
    x: b64urlEncode(deviceKey), da: b64urlEncode(deviceMac),
  };
  if (options.register) frame.k = b64urlEncode(options.register);
  if (options.push !== undefined) frame.p = options.push;
  return JSON.stringify(frame);
}

export async function record(
  key: Uint8Array,
  device: string,
  seq: number,
  body: string,
): Promise<{ d: string; n: number; b: string; a: string }> {
  const blob = new TextEncoder().encode(body);
  const mac = await tag(await importAuthKey(key), recordInput(device, seq, blob));
  return { d: device, n: seq, b: b64urlEncode(blob), a: b64urlEncode(mac) };
}

export class Client {
  private messages: string[] = [];
  private waiters: (() => void)[] = [];
  closed: CloseInfo | null = null;

  ws!: WebSocket;
  private opening = false;
  static modes = new Map<string, string>();

  private constructor(private readonly room: string) {}

  static async connect(room: string): Promise<Client> {
    return new Client(room);
  }

  private async open(hello: string): Promise<void> {
    const response = await worker.fetch(new Request(`http://localhost/r/${this.room}`, {
      headers: { Upgrade: "websocket", [HELLO_HEADER]: b64urlEncode(new TextEncoder().encode(hello)) },
    }), { ...env, ATTEST_MODE: Client.modes.get(this.room) ?? "off" } as Env);
    if (!response.webSocket) {
      const error = await response.json() as { c: string };
      this.messages.push(JSON.stringify(error));
      const codes: { [key: string]: number } = { auth: 4004, proto: 4002, full: 4003, unknown: 4006 };
      this.closed = { code: codes[error.c] ?? 4002, reason: error.c };
      this.wake();
      return;
    }
    this.ws = response.webSocket;
    this.ws.addEventListener("message", (event) => {
      this.messages.push(event.data as string);
      this.wake();
    });
    this.ws.addEventListener("close", (event) => {
      this.closed = { code: event.code, reason: event.reason };
      this.wake();
    });
    this.ws.accept();
  }

  private wake(): void {
    for (const waiter of this.waiters.splice(0)) waiter();
  }

  send(frame: string | object): void {
    const text = typeof frame === "string" ? frame : JSON.stringify(frame);
    if (this.ws) this.ws.send(text);
    else if (!this.opening) {
      this.opening = true;
      void this.open(text).catch(() => {
        this.closed = { code: 4002, reason: "internal error" };
        this.wake();
      });
    } else throw new Error("upgrade still pending");
  }

  held: number | null = null;

  async next(): Promise<any> {
    for (;;) {
      while (this.messages.length === 0) {
        if (this.closed) throw new Error(`closed with ${this.closed.code}`);
        await this.settle();
      }
      const frame = JSON.parse(this.messages.shift()!);
      if (frame.t !== "held") return frame;
      this.held = frame.n;
    }
  }

  async nextRaw(): Promise<string> {
    while (this.messages.length === 0) {
      if (this.closed) throw new Error(`closed with ${this.closed.code}`);
      await this.settle();
    }
    return this.messages.shift()!;
  }

  async closure(): Promise<CloseInfo> {
    while (!this.closed) await this.settle();
    return this.closed;
  }

  async quiet(): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, 100));
    if (this.messages.length > 0) throw new Error(`unexpected frame: ${this.messages[0]}`);
  }

  private settle(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("timed out waiting for the relay")), 3000);
      this.waiters.push(() => {
        clearTimeout(timer);
        resolve();
      });
    });
  }
}
