# circles-relay

A store-and-forward relay for the CiRCLES / CirclesGo shared shopping list. One Cloudflare Worker,
one Durable Object per room, WebSockets only.

The Worker is a dumb pipe. Records arrive sealed, are stored as opaque bytes, and are replayed
verbatim. Nothing here decrypts, parses or inspects a record, and no key that could decrypt one ever
reaches this service.

## Endpoints

```
wss://<host>/r/:roomId      roomId matches /^[0-9a-f]{32}$/
GET  /health                200 "ok"
GET  /                      302 to the repository
```

Everything else, including `/` with a query string, is 400.

## Protocol

JSON text frames. Binary values are base64url without padding.

Client to server:

```jsonc
{ "t": "hello", "d": "a1b2c3d4", "v": { "a1b2c3d4": 12 }, "k": "<key>", "ts": 1757030400, "a": "<tag>" }
{ "t": "ops", "o": [ { "d": "a1b2c3d4", "n": 13, "b": "<sealed>", "a": "<tag>" } ] }
{ "t": "bye" }
```

Server to client:

```jsonc
{ "t": "ops", "o": [ … ] }             // catch-up after hello, then fan-out from peers
{ "t": "err", "c": "rate", "m": "…" }  // always followed by a close with the matching code
```

`hello` is the required first frame. The reply is always an `ops` frame, empty when the client is
already up to date. Catch-up is chunked so no frame exceeds 4 KB.

### Auth tags

```
hello tag  = HMAC-SHA256(relayAuthKey, "hello" ‖ 0x00 ‖ deviceId ‖ 0x00 ‖ uint64be(ts))[0..16]
record tag = HMAC-SHA256(relayAuthKey, deviceId ‖ 0x00 ‖ uint64be(seq) ‖ sealedBlob)[0..16]
```

`deviceId` is fed in as its 8 ASCII hex characters, not as the 4 bytes they encode. `sealedBlob` is
the decoded blob, not its base64url text. Tags are the first 16 bytes of the HMAC and are compared
in constant time.

The first `hello` for a room must carry `k`, the 32-byte `relayAuthKey`; it is stored only once the
hello tag verifies against it. Later `hello` frames carrying `k` are ignored and verified against
the stored key. Record tags are stored alongside the blob and replayed unchanged, so receivers can
verify them too.

`(device, seq)` is the only identity a record has. Re-sending one is a no-op, never an error, and is
not fanned out again. Records are never reordered, rewritten or deduplicated by content.

## Limits

| Limit | Value | Close code |
| --- | --- | --- |
| Frame size | 4 KB | `4002` |
| Records per `ops` frame | 32 | `4002` |
| Message rate per socket | 20 per 10 s | `4001` |
| Concurrent sockets per room | 8 | `4003` |
| Stored records per room | 500 | `4005` |
| Bad, missing or stale auth | — | `4004` |
| Room lifetime | 48 h sliding from the last write | `1001` |

Every close is preceded by an `err` frame whose `c` is a stable slug for the close code — `rate`
(4001), `proto` (4002), `full` (4003), `auth` (4004), `storage` (4005) — and whose `m` is human
text that may change. Match on `c`, never on `m`.

## Hibernation

The object uses the WebSocket Hibernation API, so an idle room with open sockets bills no duration.
Two rules follow, and breaking either one breaks the service on the free plan:

- Nothing that must outlive a message may live in an instance field or module scope. Room state is
  in SQLite; per-socket state (device id, rate-limit bucket) is in `serializeAttachment`.
- Keepalive is `setWebSocketAutoResponse("ping" → "pong")`, which never wakes the object, and the
  only scheduled work is `alarm()`. No timers, no ticks.

There is no HTTP polling endpoint and there must never be one: outbound WebSocket messages are free
while inbound requests are billed, so polling converts the cheap path into the expensive one.

## Develop and deploy

```bash
npm install
npm test
npm run typecheck
npm run dev
```

```bash
npx wrangler deploy --env staging
```

```bash
npx wrangler deploy --env production
```

CI deploys on tags: `staging-*` to staging, `v*` to production, using a `CLOUDFLARE_API_TOKEN`
repository secret scoped to **Edit Cloudflare Workers** and nothing else. There are no Worker
secrets or environment variables — room keys arrive from clients at runtime and live only in each
object's own storage.

After the first deploy, enable Workers Analytics and set an alert at 50,000 requests/day, half the
free-plan cap. Exhausting it fails silently for every user at once.

## Logging

Counts and error codes only. Never log a blob, a tag, a key, a room id or a full URL.

## Push notifications (later phase)

Not built here. The open question was whether the Worker's outbound APNs/FCM calls would count
against the 100,000 requests/day allowance. They do not: Cloudflare does not bill subrequests made
from a Worker, and only the inbound request — for a WebSocket, the initial upgrade — is billable.
Two limits do apply instead: 50 subrequests per invocation on the free plan, and six connections per
invocation simultaneously awaiting response headers. A fan-out that pushes to more than 50 devices
in one message must therefore be batched across invocations rather than looped in place.
