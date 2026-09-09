# CirclesRelay

Store-and-forward relay for the CiRCLES app. One Cloudflare Worker, one Durable Object per room, and WebSockets.

## Endpoints

```
wss://<host>/r/:roomId      roomId matches /^[0-9a-f]{32}$/
GET  /health                200 "ok"
GET  /                      302 to the repository
```

Everything else, including `/` with a query string, is 400.

## Protocol

JSON text frames, binary values base64url without padding.

```jsonc
// client -> server
{ "t": "hello", "d": "a1b2c3d4", "v": { "a1b2c3d4": 12 }, "k": "<key>", "ts": 1757030400, "a": "<tag>" }
{ "t": "ops", "o": [ { "d": "a1b2c3d4", "n": 13, "b": "<sealed>", "a": "<tag>" } ] }
{ "t": "bye" }

// server -> client
{ "t": "ops", "o": [ … ] }             // catch-up after hello, then fan-out from peers
{ "t": "err", "c": "auth", "m": "…" }  // always followed by a close
```

`hello` is the required first frame; the reply is always an `ops` frame, empty when already current. Frames never exceed 4 KB, so catch-up is chunked.

`(device, seq)` is a record's only identity. Records are never reordered, rewritten, or deduplicated by content.

### Auth tags

```
hello tag  = HMAC-SHA256(relayAuthKey, "hello" ‖ 0x00 ‖ deviceId ‖ 0x00 ‖ uint64be(ts))[0..16]
record tag = HMAC-SHA256(relayAuthKey, deviceId ‖ 0x00 ‖ uint64be(seq) ‖ sealedBlob)[0..16]
```

`deviceId` is its 8 ASCII hex characters, not the 4 bytes they encode; `sealedBlob` is the decoded blob, not its base64url text. Tags are compared in constant time and stored alongside each record so receivers can verify them too.

**Send `k`, the 32-byte `relayAuthKey`, on every `hello`.** It's stored only once and ignored after, so repeating it just costs 44 bytes. A room is deleted 48 hours after its last write, taking its key with it, so a client that only sends `k` on its first-ever `hello` gets shut out after an idle weekend. Omitting `k` for a keyless room closes `4006` (`unknown`, recoverable: reconnect and send `k`); a wrong tag closes `4004` (`auth`, not recoverable by retrying).

## Limits

| Limit | Value | Close code | `err` slug |
| --- | --- | --- | --- |
| Frame size | 4 KB | `4002` | `proto` |
| Records per `ops` frame | 32 | `4002` | `proto` |
| Message rate per socket | 20 per 10 s | `4001` | `rate` |
| Sockets per room | 8 | `4003` | `full` |
| Stored records per room | 500 | `4005` | `storage` |
| Bad, missing, or stale auth | — | `4004` | `auth` |
| Room has no key yet and none offered | — | `4006` | `unknown` |
| Room lifetime | 48 h sliding from last write | `1001` | — |

Match on `c`, never on `m`.

## Hibernation

Idle rooms must bill no duration, so on the free plan:

- Nothing that outlives a message may sit in an instance field or module scope. Room state lives in SQLite, per-socket state in `serializeAttachment`.
- Keepalive is `setWebSocketAutoResponse("ping" → "pong")`; the only scheduled work is `alarm()`, no timers.
- No HTTP polling endpoint, ever. Outbound WebSocket messages are free, inbound requests are billed, so polling would turn the cheap path into the expensive one.

## Develop and deploy

```bash
npm install && npm test
npm run dev
npx wrangler deploy --env staging
```

CI deploys on published GitHub Releases: a prerelease goes to staging, a full release to production, using a `CLOUDFLARE_API_TOKEN` secret scoped to Edit Cloudflare Workers. There are no Worker secrets: room keys arrive from clients at runtime and live only in each object's storage.

After the first deploy, set a Workers Analytics alert at 50,000 requests/day, half the free-plan cap, since exhausting it fails silently for everyone at once.

Log counts and error codes only, never a blob, tag, key, room id, or full URL.

## Push notifications

Not built. Outbound APNs/FCM calls wouldn't count against the 100,000 requests/day allowance (subrequests are unbilled, only the inbound request is), but each invocation is capped at 50 subrequests and six connections awaiting response headers, so a fan-out past 50 devices would need batching.
