export type CborValue = number | string | Uint8Array | boolean | null | CborValue[] | { [key: string]: CborValue };

const MAX_DEPTH = 8;

class Malformed extends Error {}

class Reader {
  private at = 0;

  constructor(private readonly bytes: Uint8Array) {}

  get done(): boolean {
    return this.at >= this.bytes.length;
  }

  private take(count: number): Uint8Array {
    if (count < 0 || this.at + count > this.bytes.length) throw new Malformed("truncated");
    const slice = this.bytes.subarray(this.at, this.at + count);
    this.at += count;
    return slice;
  }

  private byte(): number {
    return this.take(1)[0];
  }

  private argument(info: number): number {
    if (info < 24) return info;
    if (info === 24) return this.byte();
    if (info === 25) {
      const bytes = this.take(2);
      return (bytes[0] << 8) | bytes[1];
    }
    if (info === 26) {
      const bytes = this.take(4);
      return ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) >>> 0;
    }
    if (info === 27) {
      const wide = new DataView(this.take(8).slice().buffer).getBigUint64(0);
      if (wide > BigInt(Number.MAX_SAFE_INTEGER)) throw new Malformed("argument too large");
      return Number(wide);
    }
    throw new Malformed("indefinite length");
  }

  value(depth = 0): CborValue {
    if (depth > MAX_DEPTH) throw new Malformed("too deeply nested");
    const initial = this.byte();
    const major = initial >> 5;
    const info = initial & 0x1f;

    switch (major) {
      case 0:
        return this.argument(info);
      case 1:
        return -1 - this.argument(info);
      case 2:
        return this.take(this.argument(info)).slice();
      case 3:
        return new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(this.take(this.argument(info)));
      case 4: {
        const count = this.argument(info);
        const out: CborValue[] = [];
        for (let i = 0; i < count; i++) out.push(this.value(depth + 1));
        return out;
      }
      case 5: {
        const count = this.argument(info);
        const out: { [key: string]: CborValue } = {};
        for (let i = 0; i < count; i++) {
          const key = this.value(depth + 1);
          if (typeof key !== "string") throw new Malformed("non-text map key");
          out[key] = this.value(depth + 1);
        }
        return out;
      }
      case 7:
        if (info === 20) return false;
        if (info === 21) return true;
        if (info === 22) return null;
        throw new Malformed("unsupported simple value");
      default:
        throw new Malformed("unsupported major type");
    }
  }
}

export function decodeCbor(bytes: Uint8Array): CborValue | null {
  try {
    const reader = new Reader(bytes);
    const value = reader.value();
    return reader.done ? value : null;
  } catch {
    return null;
  }
}
