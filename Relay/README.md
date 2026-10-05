# CirclesRelay

Store-and-forward relay for the shared Buys feature of the CiRCLES apps: one Cloudflare Worker, one Durable Object per room, and WebSockets. The wire protocol both apps speak, over the relay and over Bluetooth, is documented byte by byte in [PROTOCOL.html](PROTOCOL.html).

## Develop and deploy

```bash
npm install && npm test
npm run dev
npx wrangler deploy --env staging
npx wrangler deploy --env production
```

CI deploys on published GitHub Releases: a prerelease goes to staging, a full release to production, using a `CLOUDFLARE_API_TOKEN` secret scoped to Edit Cloudflare Workers. Room keys arrive from clients at runtime and live only in each object's storage, but the push path (below) does need Worker secrets.

## Push wake-ups

A member whose app is suspended is woken with a content-free push so it can reconnect and catch up. The relay never sees plaintext, so it never composes the notification body. Tokens ride in on `hello` and expire with the room.

Secrets, set per environment with `npx wrangler secret put NAME --env staging` (and again for `--env production`), or in a gitignored `.dev.vars` for `wrangler dev`:

| Secret | Where it comes from |
| --- | --- |
| `APNS_SANDBOX_KEY_P8` | APNs auth key `.p8`, whole PEM body |
| `APNS_SANDBOX_KEY_ID` | The 10-character key ID for that key |
| `APNS_PRODUCTION_KEY_P8` | A second APNs auth key, for production tokens |
| `APNS_PRODUCTION_KEY_ID` | The 10-character key ID for that key |
| `FCM_SERVICE_ACCOUNT` | Firebase service-account JSON, verbatim |

`APNS_TEAM_ID` and `APNS_TOPIC` are plain vars in `wrangler.jsonc`. An environment whose key is missing is skipped silently — devices on the other environment still get woken.

## Device attestation

A `hello` may carry an `at` object proving the socket belongs to a genuine build on genuine hardware — App Attest from Apple platforms, Play Integrity from Android. It is a tagged union with no default branch: an unrecognised kind is refused rather than waved through. See `PROTOCOL.html` for the wire format and what each path checks.

**Attestation is always on, and there is no way to turn it off on a deployed relay.** It needs no
variable to enable it: with nothing configured at all, every hello must carry evidence that
verifies, and a hello that does not is closed 4004. There is deliberately no production switch —
`ATTEST_MODE` is not in `wrangler.jsonc` and setting it as a secret does nothing.

It can only be turned down on a local run, which needs **both** of:

| Variable | Set in | Effect |
| --- | --- | --- |
| `ATTEST_DEV_OVERRIDE` | `.dev.vars` only — never a secret | Permits `ATTEST_MODE` to be honoured at all |
| `ATTEST_MODE` | `.dev.vars` | `optional` to let unattested devices join, `off` to skip checking entirely |

Both are required, and the request must have arrived on a loopback host — `localhost`,
`127.0.0.1`, `::1`, or `10.0.2.2` for the Android emulator. A deployed relay fails both the
host test and, unless someone deliberately puts `ATTEST_DEV_OVERRIDE` in its secrets, the
variable test. Anything other than `optional` or `off` falls back to required, so a typo cannot
open it either.

The host is read from the request at the WebSocket upgrade, not from anything a client sends in
a frame, so a peer cannot claim to be local.

Requiring it has teeth: it locks out any client that cannot attest, permanently. That is the
Simulator, Mac and Catalyst builds, app extensions — `SharedBuysWidget` included — and Android
devices with no Play services.

Clients know the difference between a refusal they can retry and one they cannot. A hello that carried no evidence and came back 4004 is permanent, so both apps surface it and stop reconnecting rather than retrying every 30 seconds for the life of the room; a refusal after evidence *was* sent clears the stored enrollment and retries.

The plain vars are `APP_ATTEST_TEAM_ID`, `APP_ATTEST_BUNDLE_ID`, `APP_ATTEST_ENVIRONMENT` (`production`, or `development` to also accept development-signed attestations), `PLAY_PACKAGE_NAME` and `PLAY_MIN_VERDICT` (`basic`, `device` or `strong`).

| Secret | Where it comes from |
| --- | --- |
| `PLAY_SERVICE_ACCOUNT` | Service-account JSON with the Play Integrity API enabled; falls back to `FCM_SERVICE_ACCOUNT` when unset |
