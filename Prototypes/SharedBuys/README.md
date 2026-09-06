# Shared Buys prototype

A standalone SwiftUI harness for the shared Buys feature described in [PLAN.md](PLAN.md).
It has no dependencies and does not touch the CiRCLES app or its data.

```bash
cd Prototypes/SharedBuys && xcodegen generate && open SharedBuys.xcodeproj
```

Three simulated phones (Justin, Aoi, Mika) live in one app.

The screen mirrors the real app's shell: the hall map behind, `UnifiedPanel` pinned over it
with the Circles / Favorites / Buys segmented picker, and the shared list inside the Buys
segment. There is no tab bar, because the app does not have one.

Everything in a black capsule labelled **HARNESS** is prototype scaffolding, not proposed UI:
the phone switcher at the top, and the slider button that opens the harness sheet (per-phone
Bluetooth / proximity / internet toggles, the replica's version vector and digest, traffic
totals, and every byte that crossed a radio).

The mock Live Activity card floats above the panel where the lock screen would put it.

The app-facing UI is Japanese by default and says nothing about Bluetooth, relays, or sync
state; the JA/EN button in the harness capsule flips the locale to check both.

The server side is built and lives in `../CirclesServer`; its README documents the protocol.

`Transport/Mesh.swift` is the real protocol (version vectors, digest short-circuiting,
delta-only transfer) over an in-process link; `Model/` is the op log and the fold that
both platforms must implement identically.
