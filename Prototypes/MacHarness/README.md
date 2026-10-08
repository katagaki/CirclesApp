# MacHarness

A Mac that stands in for a second phone. It runs the **same ORBiT sources** as the iOS
app — the same change log, crypto, relay client and Bluetooth transport — so a test with
one iPhone and this harness exercises the real sync engine on both ends, not a mock.

```bash
xcodegen generate
open MacHarness.xcodeproj
```

The target compiles `../../ORBiT` directly rather than linking the framework, which is
what gives it the internal transport calls the harness drives. ActivityKit is iOS-only,
so `SharedBuysSession+Activity.swift` supplies no-op stubs off iOS; nothing else in
ORBiT is platform-bound.

## Two ways to drive it

The window is for watching — status, the join QR, the item list, the log. `--cli` is for
the tests where nobody can be touching either device:

```bash
MacHarness.app/Contents/MacOS/MacHarness --cli --help
MacHarness.app/Contents/MacOS/MacHarness --cli --start --watch 60
MacHarness.app/Contents/MacOS/MacHarness --cli --join "circles-app://buys-join?v=1&e=0&k=…"
MacHarness.app/Contents/MacOS/MacHarness --cli --add "新刊" --cost 1200 --after 30
```

Both modes share one stored session, so you can join in the window and write from the
shell. The window also mirrors its log to `~/Library/Logs/MacHarness.log` for `tail -f`.

## Pairing with the phone

The harness shows its join link as a QR code — scan it with the phone. Or paste the
phone's link into the join field and press Join. Either way both ends land in one room.

## Testing Bluetooth

Turn on **Carry changes over Bluetooth**, and grant the Bluetooth prompt on first run.
The Mac advertises and scans exactly as a phone does. Watch the peer count on both ends,
then stop the relay (or point it at a dead port) so the radio is the only path left, and
write on one side.

## Testing APNs

The push is sent by the relay when a member is registered but not connected, so the Mac
plays the member who writes and the phone is the one asleep.

1. Run the relay where both machines can reach it:
   `cd ../../../CirclesRelay && npx wrangler dev --ip 0.0.0.0 --port 8787`
2. Point the harness and the phone at `ws://<the Mac's LAN address>:8787`.
3. Join both to one room.
4. Queue the write and lock the phone while it counts down:
   `MacHarness --cli --add "新刊" --cost 1200 --after 30 --watch 45`. The window has the
   same thing as an **Add in 10 seconds** button.

What lands on the phone's lock screen came from APNs, because nothing was touching
either device when it was written. The relay's push is content-free; the phone syncs and
renders locally.

The harness cannot *receive* APNs — it is not an iOS app, and the token it would
register is not an iOS token. It writes; the phone wakes.
