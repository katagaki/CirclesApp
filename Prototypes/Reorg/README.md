# Reorg prototypes

Ten standalone SwiftUI harness apps. Each one tries a different way to reorganize CiRCLES now that it has Map, Catalog, Favorites, Buys, Shared Buys, Navigation, My Comiket, Offline Mode and Guest Mode. All of them keep the sheet over the map. On a compact width (iPhone, iPhone Duo closed) it is a real `.sheet` with detents. On a wide one (iPhone Duo open, iPad) it is a floating glass panel.

| # | Variant | Idea |
| --- | --- | --- |
| 01 | Dock | A four-tab dock inside the sheet (Explore, Favorites, Buys, Me) |
| 02 | Launcher | The sheet opens on shortcuts and feature tiles with live subtitles |
| 03 | Spotlight | One search field finds every circle, screen, action and setting |
| 04 | Modes | Plan mode before the event, Go mode on the day |
| 05 | Library | A grouped Files/Mail-style list of every feature with counts |
| 06 | Today | A contextual "what now?" card feed |
| 07 | Toolbelt | A tool rail on the map; the sheet is only for browsing |
| 08 | Layers | Every feature is a map layer; the sheet lists the focused layer |
| 09 | Wallet | Feature cards in a Wallet-style stack |
| 10 | Hub | Only Circles and Buys, with everything else in a Me hub |

`Kit/` is compiled into every app. It holds mock data, the drawn hall map, `MapStage` (sheet or panel over the map), the shared feature screens and the `Harness` state. Each variant's README maps every feature and lists its `-screen` values.

```bash
./make-project.sh 01-Dock Dock "01 Dock"
./build.sh 01-Dock Dock          # installs on the "Reorg iPhone", "Reorg iPhone Duo" and "Reorg iPad" simulators
REORG_SIMS="Some Sim" ./build.sh 01-Dock Dock
```

The black **HARNESS** capsule under the status bar is scaffolding, not proposed UI. It toggles Guest, Offline, Navigating and Shared Buys. Every app also takes these launch arguments: `-guest -offline -navigating -sharedBuys -hideHarness -screen <name> -detent small|medium|large -circle <id>`.

Everything is mock data. Nothing touches the real app, its database or the relay.
