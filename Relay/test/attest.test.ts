import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { decodeCbor } from "../src/cbor";
import {
  type AttestEnv,
  type Enrolled,
  attestMode,
  verifyAttestation,
} from "../src/attest";
import { attestInput, sha256 } from "../src/proto";
import { resetBearers } from "../src/push";
import { Client, authKey, helloFrame, roomId } from "./client";
import {
  type AssertionKeys,
  appIdHash,
  assertion,
  assertionKeys,
  base64url,
  cborArray,
  cborBytes,
  cborMap,
  cborText,
  serviceAccountJson,
} from "./attest";

const TEAM = "YYM4Z6MU8F";
const BUNDLE = "com.tsubuzaki.CiRCLES";
const PACKAGE = "com.tsubuzaki.circlesgo";

let account = "";
let payload: object | null = null;
let decodeStatus = 200;
const real = globalThis.fetch;

function env(overrides: Partial<AttestEnv> = {}): AttestEnv {
  return {
    ATTEST_MODE: "required",
    APP_ATTEST_TEAM_ID: TEAM,
    APP_ATTEST_BUNDLE_ID: BUNDLE,
    PLAY_PACKAGE_NAME: PACKAGE,
    PLAY_SERVICE_ACCOUNT: account,
    ...overrides,
  };
}

function playPayload(overrides: Record<string, unknown> = {}, requestHash = ""): object {
  return {
    tokenPayloadExternal: {
      requestDetails: {
        requestPackageName: PACKAGE,
        requestHash,
        timestampMillis: String(Date.now()),
      },
      appIntegrity: { appRecognitionVerdict: "PLAY_RECOGNIZED", packageName: PACKAGE },
      deviceIntegrity: { deviceRecognitionVerdict: ["MEETS_BASIC_INTEGRITY", "MEETS_DEVICE_INTEGRITY"] },
      ...overrides,
    },
  };
}

beforeAll(async () => {
  account = await serviceAccountJson();
  vi.stubGlobal("fetch", (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    if (url.includes("oauth2.googleapis.com")) {
      return Promise.resolve(Response.json({ access_token: "test-access-token", expires_in: 3599 }));
    }
    if (url.includes("playintegrity.googleapis.com")) {
      return Promise.resolve(Response.json(payload ?? {}, { status: decodeStatus }));
    }
    return real(input as never, init as never);
  });
});

afterAll(() => {
  vi.unstubAllGlobals();
});

beforeEach(() => {
  payload = null;
  decodeStatus = 200;
  resetBearers();
});

describe("cbor", () => {
  it("reads the shapes an attestation uses", () => {
    expect(decodeCbor(new Uint8Array(cborMap([["a", [1]]])))).toEqual({ a: 1 });
    expect(decodeCbor(new Uint8Array([...cborBytes(new Uint8Array([7, 8]))]))).toEqual(new Uint8Array([7, 8]));
    expect(decodeCbor(new Uint8Array(cborText("apple-appattest")))).toBe("apple-appattest");
    expect(decodeCbor(new Uint8Array(cborArray([[1], [2]])))).toEqual([1, 2]);
    expect(decodeCbor(new Uint8Array([0x19, 0x01, 0x00]))).toBe(256);
    expect(decodeCbor(new Uint8Array([0x1a, 0x00, 0x01, 0x00, 0x00]))).toBe(65536);
  });

  it("refuses malformed, trailing, indefinite and over-nested input", () => {
    expect(decodeCbor(new Uint8Array([0x42, 0x01]))).toBeNull();
    expect(decodeCbor(new Uint8Array([0x01, 0x01]))).toBeNull();
    expect(decodeCbor(new Uint8Array([0x5f, 0x41, 0x01, 0xff]))).toBeNull();
    expect(decodeCbor(new Uint8Array(Array(12).fill(0x81)))).toBeNull();
    expect(decodeCbor(new Uint8Array([0xa1, 0x01, 0x01]))).toBeNull();
  });
});

describe("mode", () => {
  it("is off unless the environment opts in", () => {
    expect(attestMode({})).toBe("off");
    expect(attestMode({ ATTEST_MODE: "nonsense" })).toBe("off");
    expect(attestMode({ ATTEST_MODE: "optional" })).toBe("optional");
    expect(attestMode({ ATTEST_MODE: "required" })).toBe("required");
  });
});

describe("dispatch", () => {
  const hash = new Uint8Array(32);

  it("refuses evidence that names no kind, and never falls through to a default", async () => {
    for (const evidence of [null, undefined, "appattest", 7, {}, { t: "pinkyswear" }, { t: ["appattest"] }]) {
      const result = await verifyAttestation(env(), evidence, hash, null);
      expect(result.ok).toBe(false);
    }
  });

  it("refuses to let an enrolled device switch mechanism", async () => {
    const enrolled: Enrolled = { kind: "playintegrity", keyId: null, pubkey: null, counter: 0 };
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(new Uint8Array(32)) }, hash, enrolled);
    expect(result).toEqual({ ok: false, reason: "attestation kind changed" });
  });
});

describe("app attest", () => {
  const hash = new Uint8Array(32).fill(9);

  it("needs the team and bundle to be configured", async () => {
    const result = await verifyAttestation({ ATTEST_MODE: "required" }, { t: "appattest", k: "" }, hash, null);
    expect(result).toEqual({ ok: false, reason: "app attest unconfigured" });
  });

  it("refuses a key id that is not a 32 byte digest", async () => {
    for (const k of ["", base64url(new Uint8Array(31)), "!!!", 7]) {
      const result = await verifyAttestation(env(), { t: "appattest", k }, hash, null);
      expect(result).toEqual({ ok: false, reason: "bad key id" });
    }
  });

  it("refuses evidence carrying neither an attestation nor an assertion", async () => {
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(new Uint8Array(32)) }, hash, null);
    expect(result).toEqual({ ok: false, reason: "no attestation or assertion" });
  });

  it("refuses an attestation object that is not decodable CBOR", async () => {
    const result = await verifyAttestation(
      env(),
      { t: "appattest", k: base64url(new Uint8Array(32)), o: base64url(new Uint8Array([0xff, 0xff])) },
      hash,
      null,
    );
    expect(result).toEqual({ ok: false, reason: "bad attestation object" });
  });

  it("refuses an attestation that does not claim Apple's format", async () => {
    const object = cborMap([
      ["fmt", cborText("packed")],
      ["authData", cborBytes(new Uint8Array(87))],
      ["attStmt", [...cborMap([["x5c", cborArray([cborBytes(new Uint8Array(4)), cborBytes(new Uint8Array(4))])]])]],
    ]);
    const result = await verifyAttestation(
      env(),
      { t: "appattest", k: base64url(new Uint8Array(32)), o: base64url(object) },
      hash,
      null,
    );
    expect(result).toEqual({ ok: false, reason: "bad attestation format" });
  });

  it("refuses a chain that does not reach Apple's root", async () => {
    const object = cborMap([
      ["fmt", cborText("apple-appattest")],
      ["authData", cborBytes(new Uint8Array(87))],
      [
        "attStmt",
        [...cborMap([["x5c", cborArray([cborBytes(new Uint8Array(4)), cborBytes(new Uint8Array(4))])]])],
      ],
    ]);
    const result = await verifyAttestation(
      env(),
      { t: "appattest", k: base64url(new Uint8Array(32)), o: base64url(object) },
      hash,
      null,
    );
    expect(result).toEqual({ ok: false, reason: "untrusted certificate chain" });
  });

  it("refuses a single certificate, which can only be self-signed", async () => {
    const object = cborMap([
      ["fmt", cborText("apple-appattest")],
      ["authData", cborBytes(new Uint8Array(87))],
      ["attStmt", [...cborMap([["x5c", cborArray([cborBytes(new Uint8Array(4))])]])]],
    ]);
    const result = await verifyAttestation(
      env(),
      { t: "appattest", k: base64url(new Uint8Array(32)), o: base64url(object) },
      hash,
      null,
    );
    expect(result).toEqual({ ok: false, reason: "bad certificate chain" });
  });
});

describe("app attest assertions", () => {
  let keys: AssertionKeys;
  let rpIdHash: Uint8Array;
  let enrolled: Enrolled;
  const hash = new Uint8Array(32).fill(4);

  beforeEach(async () => {
    keys = await assertionKeys();
    rpIdHash = await appIdHash(TEAM, BUNDLE);
    enrolled = { kind: "appattest", keyId: new Uint8Array(32).fill(1), pubkey: keys.publicKey, counter: 3 };
  });

  it("accepts a signature over the nonce and reports the new counter", async () => {
    const s = await assertion(keys, rpIdHash, 4, hash);
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(enrolled.keyId!), s }, hash, enrolled);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.kind).toBe("appattest");
      expect(result.counter).toBe(4);
    }
  });

  it("refuses a counter that does not advance", async () => {
    for (const counter of [0, 3]) {
      const s = await assertion(keys, rpIdHash, counter, hash);
      const result = await verifyAttestation(
        env(),
        { t: "appattest", k: base64url(enrolled.keyId!), s },
        hash,
        enrolled,
      );
      expect(result).toEqual({ ok: false, reason: "assertion counter did not advance" });
    }
  });

  it("refuses an assertion bound to different client data", async () => {
    const s = await assertion(keys, rpIdHash, 4, new Uint8Array(32).fill(5));
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(enrolled.keyId!), s }, hash, enrolled);
    expect(result).toEqual({ ok: false, reason: "bad assertion signature" });
  });

  it("refuses an assertion signed by another key", async () => {
    const other = await assertionKeys();
    const s = await assertion(other, rpIdHash, 4, hash);
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(enrolled.keyId!), s }, hash, enrolled);
    expect(result).toEqual({ ok: false, reason: "bad assertion signature" });
  });

  it("refuses an assertion naming another app", async () => {
    const s = await assertion(keys, await appIdHash(TEAM, "com.example.other"), 4, hash);
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(enrolled.keyId!), s }, hash, enrolled);
    expect(result).toEqual({ ok: false, reason: "app id mismatch" });
  });

  it("refuses an assertion from a device that never enrolled", async () => {
    const s = await assertion(keys, rpIdHash, 4, hash);
    const result = await verifyAttestation(env(), { t: "appattest", k: base64url(new Uint8Array(32)), s }, hash, null);
    expect(result).toEqual({ ok: false, reason: "device is not enrolled" });
  });
});

describe("play integrity", () => {
  const hash = new Uint8Array(32).fill(2);

  it("needs a package name and a service account", async () => {
    const result = await verifyAttestation(
      { ATTEST_MODE: "required" },
      { t: "playintegrity", tk: "token" },
      hash,
      null,
    );
    expect(result).toEqual({ ok: false, reason: "play integrity unconfigured" });
  });

  it("refuses a missing or oversized token", async () => {
    for (const tk of [undefined, "", 7, "x".repeat(8193)]) {
      const result = await verifyAttestation(env(), { t: "playintegrity", tk }, hash, null);
      expect(result).toEqual({ ok: false, reason: "bad integrity token" });
    }
  });

  it("accepts a verdict that names our package and binds our request hash", async () => {
    payload = playPayload({}, base64url(hash));
    const result = await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null);
    expect(result).toEqual({ ok: true, kind: "playintegrity", keyId: null, pubkey: null, counter: 0 });
  });

  it("refuses a verdict bound to someone else's request", async () => {
    payload = playPayload({}, base64url(new Uint8Array(32).fill(3)));
    const result = await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null);
    expect(result).toEqual({ ok: false, reason: "integrity request hash mismatch" });
  });

  it("refuses a verdict for another package", async () => {
    payload = playPayload(
      {
        requestDetails: {
          requestPackageName: "com.example.other",
          requestHash: base64url(hash),
          timestampMillis: String(Date.now()),
        },
      },
      base64url(hash),
    );
    const result = await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null);
    expect(result).toEqual({ ok: false, reason: "integrity package mismatch" });
  });

  it("refuses an app Play does not recognise", async () => {
    payload = playPayload(
      { appIntegrity: { appRecognitionVerdict: "UNRECOGNIZED_VERSION", packageName: PACKAGE } },
      base64url(hash),
    );
    const result = await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null);
    expect(result).toEqual({ ok: false, reason: "app not recognised by play" });
  });

  it("refuses a device below the configured verdict", async () => {
    payload = playPayload({ deviceIntegrity: { deviceRecognitionVerdict: ["MEETS_BASIC_INTEGRITY"] } }, base64url(hash));
    expect(await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null)).toEqual({
      ok: false,
      reason: "device integrity too low",
    });
    const relaxed = await verifyAttestation(
      env({ PLAY_MIN_VERDICT: "basic" }),
      { t: "playintegrity", tk: "token" },
      hash,
      null,
    );
    expect(relaxed.ok).toBe(true);
  });

  it("refuses an emptied or absent device verdict", async () => {
    payload = playPayload({ deviceIntegrity: { deviceRecognitionVerdict: [] } }, base64url(hash));
    expect(await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null)).toEqual({
      ok: false,
      reason: "device integrity too low",
    });
    payload = playPayload({ deviceIntegrity: {} }, base64url(hash));
    expect(await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null)).toEqual({
      ok: false,
      reason: "no device verdict",
    });
  });

  it("refuses a stale verdict", async () => {
    payload = playPayload(
      {
        requestDetails: {
          requestPackageName: PACKAGE,
          requestHash: base64url(hash),
          timestampMillis: String(Date.now() - 600_000),
        },
      },
      base64url(hash),
    );
    const result = await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null);
    expect(result).toEqual({ ok: false, reason: "stale integrity token" });
  });

  it("refuses a token Google will not decode", async () => {
    decodeStatus = 400;
    payload = { error: { code: 400 } };
    const result = await verifyAttestation(env(), { t: "playintegrity", tk: "token" }, hash, null);
    expect(result).toEqual({ ok: false, reason: "play integrity rejected the token" });
  });
});

describe("client data", () => {
  it("binds the room, the device and the hello timestamp", async () => {
    const one = await sha256(attestInput("aaaaaaaa", 100, "r1"));
    expect(one).toEqual(await sha256(attestInput("aaaaaaaa", 100, "r1")));
    for (const other of [
      attestInput("bbbbbbbb", 100, "r1"),
      attestInput("aaaaaaaa", 101, "r1"),
      attestInput("aaaaaaaa", 100, "r2"),
    ]) {
      expect(await sha256(other)).not.toEqual(one);
    }
  });
});

describe("the hello gate", () => {
  it("lets a hello through untouched while attestation is off", async () => {
    const room = roomId();
    const key = authKey();
    const client = await Client.connect(room);
    client.send(await helloFrame(key, "aaaaaaaa", {}, { register: key }));
    expect(await client.next()).toEqual({ t: "ops", o: [] });
  });

  it("accepts a hello carrying evidence it is not yet configured to check", async () => {
    const room = roomId();
    const key = authKey();
    const client = await Client.connect(room);
    const frame = JSON.parse(await helloFrame(key, "aaaaaaaa", {}, { register: key }));
    frame.at = { t: "playintegrity", tk: "x".repeat(2000) };
    client.send(JSON.stringify(frame));
    expect(await client.next()).toEqual({ t: "ops", o: [] });
  });
});
