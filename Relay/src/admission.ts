import { MAX_ATTEST_FRAME_BYTES } from "./attest";
import { b64urlDecode } from "./proto";

export const HELLO_HEADER = "X-Circles-Hello";
export const AUTHENTICATED_HEADER = "X-Circles-Authenticated";

export function rejection(status: number, code: string, message: string): Response {
  return Response.json({ t: "err", c: code, m: message }, { status });
}

export function readHello(request: Request): { [key: string]: unknown } | null {
  const value = request.headers.get(HELLO_HEADER);
  if (!value || value.length > Math.ceil(MAX_ATTEST_FRAME_BYTES * 4 / 3)) return null;
  const bytes = b64urlDecode(value);
  if (!bytes || bytes.length > MAX_ATTEST_FRAME_BYTES) return null;
  try {
    const frame = JSON.parse(new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(bytes));
    return frame && typeof frame === "object" && !Array.isArray(frame) && frame.t === "hello" ? frame : null;
  } catch {
    return null;
  }
}
