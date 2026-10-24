import { MAX_ATTEST_FRAME_BYTES } from "./attest";
import { b64urlDecode } from "./proto";

export const HELLO_HEADER = "X-Circles-Hello";
export const ATTEST_HEADER = "X-Circles-Attest";
export const AUTHENTICATED_HEADER = "X-Circles-Authenticated";

type JsonObject = { [key: string]: unknown };

export interface Hello {
  frame: JsonObject;
  bytes: Uint8Array;
}

export function rejection(status: number, code: string, message: string): Response {
  return Response.json({ t: "err", c: code, m: message }, { status });
}

function readHeader(request: Request, name: string): { frame: JsonObject; bytes: Uint8Array } | null {
  const value = request.headers.get(name);
  if (!value || value.length > Math.ceil(MAX_ATTEST_FRAME_BYTES * 4 / 3)) return null;
  const bytes = b64urlDecode(value);
  if (!bytes || bytes.length > MAX_ATTEST_FRAME_BYTES) return null;
  try {
    const frame = JSON.parse(new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(bytes));
    return frame && typeof frame === "object" && !Array.isArray(frame) ? { frame, bytes } : null;
  } catch {
    return null;
  }
}

export function readHello(request: Request): Hello | null {
  const hello = readHeader(request, HELLO_HEADER);
  return hello?.frame.t === "hello" ? hello : null;
}

export function readEvidence(request: Request): JsonObject | null | undefined {
  if (!request.headers.has(ATTEST_HEADER)) return undefined;
  return readHeader(request, ATTEST_HEADER)?.frame ?? null;
}
