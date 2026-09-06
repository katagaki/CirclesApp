# circles-relay

Store-and-forward relay for the CiRCLES / CirclesGo shared shopping list. One Cloudflare Worker,
one Durable Object per room, WebSockets only.

A dumb pipe: records arrive sealed, are stored as opaque bytes, and are replayed verbatim. Nothing
here decrypts or inspects a record.

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

`hello` is the required first frame; the reply is always an `ops` frame, empty when already current.
Frames never exceed 4 KB, so catch-up is chunked.

`(device, seq)` is a record's only identity. Re-sending one is a no-op, not an error, is not fanned
out again, and does not count against the room's 500-record cap. Records are never reordered, rewritten, or deduplicated by content.

### Auth tags

```
hello tag  = HMAC-SHA256(relayAuthKey, "hello" ‖ 0x00 ‖ deviceId ‖ 0x00 ‖ uint64be(ts))[0..16]
record tag = HMAC-SHA256(relayAuthKey, deviceId ‖ 0x00 ‖ uint64be(seq) ‖ sealedBlob)[0..16]
```

`deviceId` goes in as its 8 ASCII hex characters, not the 4 bytes they encode; `sealedBlob` is the
decoded blob, not its base64url text. Compared in constant time.

**Send `k`, the 32-byte `relayAuthKey`, on every `hello`.** It is stored only once its tag verifies,
and later values are ignored, so repeating it costs 44 bytes and nothing else. A room is deleted 48
hours after its last write, taking its key with it — a client that sent `k` only on its very first
`hello` would be shut out of its own room after an idle weekend. Omitting `k` for a room that has no
key closes `4006` (`unknown`), which is recoverable: reconnect and send `k`. That is distinct from
`4004`, which means the tag itself was wrong and retrying will not help. Record tags are stored and replayed unchanged so receivers
can verify them too.

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

Idle rooms must bill no duration, so on the free plan two rules are load-bearing:

- Nothing that outlives a message may sit in an instance field or module scope. Room state is in
  SQLite, per-socket state in `serializeAttachment`.
- Keepalive is `setWebSocketAutoResponse("ping" → "pong")`; the only scheduled work is `alarm()`.
  No timers.

Never add an HTTP polling endpoint. Outbound WebSocket messages are free, inbound requests are
billed; polling turns the cheap path into the expensive one.

## Develop and deploy

```bash
npm install && npm test
npm run dev
npx wrangler deploy --env staging
```

CI deploys on tags — `staging-*` to staging, `v*` to production — using a `CLOUDFLARE_API_TOKEN`
secret scoped to Edit Cloudflare Workers. There are no Worker secrets: room keys arrive from clients
at runtime and live only in each object's storage.

After the first deploy, set a Workers Analytics alert at 50,000 requests/day, half the free-plan cap.
Exhausting it fails silently for everyone at once.

Log counts and error codes only — never a blob, tag, key, room id, or full URL.

## Push notifications

Not built. Outbound APNs/FCM calls will not count against the 100,000 requests/day allowance —
subrequests are not billed, only the inbound request is. Instead the caps are 50 subrequests per
invocation and six connections per invocation awaiting response headers, so a fan-out past 50
devices must be batched.
