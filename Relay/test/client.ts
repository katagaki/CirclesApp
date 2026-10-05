import { SELF } from "cloudflare:test";
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

  private constructor(readonly ws: WebSocket) {}

  static async connect(room: string): Promise<Client> {
    const response = await SELF.fetch(`http://localhost/r/${room}`, {
      headers: { Upgrade: "websocket" },
    });
    if (!response.webSocket) throw new Error(`no websocket: ${response.status}`);
    const client = new Client(response.webSocket);
    response.webSocket.accept();
    response.webSocket.addEventListener("message", (event) => {
      client.messages.push(event.data as string);
      client.wake();
    });
    response.webSocket.addEventListener("close", (event) => {
      client.closed = { code: event.code, reason: event.reason };
      client.wake();
    });
    return client;
  }

  private wake(): void {
    for (const waiter of this.waiters.splice(0)) waiter();
  }

  send(frame: string | object): void {
    this.ws.send(typeof frame === "string" ? frame : JSON.stringify(frame));
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
