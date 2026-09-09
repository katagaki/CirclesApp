import { cloudflareTest } from "@cloudflare/vitest-pool-workers";
import { defineConfig } from "vitest/config";

async function pem(algorithm: object): Promise<string> {
  const pair = (await crypto.subtle.generateKey(algorithm as never, true, ["sign", "verify"])) as CryptoKeyPair;
  const bytes = new Uint8Array((await crypto.subtle.exportKey("pkcs8", pair.privateKey)) as ArrayBuffer);
  let raw = "";
  for (const byte of bytes) raw += String.fromCharCode(byte);
  const body = btoa(raw);
  return `-----BEGIN PRIVATE KEY-----\n${body.replace(/(.{64})/g, "$1\n")}\n-----END PRIVATE KEY-----\n`;
}

export default defineConfig({
  plugins: [
    cloudflareTest(async () => ({
      wrangler: { configPath: "./wrangler.jsonc" },
      miniflare: {
        bindings: {
          APNS_TEAM_ID: "TEAMTEAM99",
          APNS_TOPIC: "com.tsubuzaki.CiRCLES",
          APNS_SANDBOX_KEY_ID: "SANDBOXKEY",
          APNS_SANDBOX_KEY_P8: await pem({ name: "ECDSA", namedCurve: "P-256" }),
          FCM_SERVICE_ACCOUNT: JSON.stringify({
            type: "service_account",
            project_id: "circles-test",
            client_email: "relay@circles-test.iam.gserviceaccount.com",
            private_key: await pem({
              name: "RSASSA-PKCS1-v1_5",
              modulusLength: 2048,
              publicExponent: new Uint8Array([1, 0, 1]),
              hash: "SHA-256",
            }),
            token_uri: "https://oauth2.googleapis.com/token",
          }),
        },
      },
    })),
  ],
});
