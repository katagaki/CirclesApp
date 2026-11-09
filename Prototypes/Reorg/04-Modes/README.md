# 04 Modes

Two modes for two moments. **Plan** is for the weeks before the event: browse the catalog, sort favorites, build the buys list, set up My Comiket participation and download event data. **Go** is for the day itself: the map takes over, the sheet drops to a strip with the next stop and your friends' live Shared Buys status, and offline readiness is always in view. A glass Plan/Go switch on the map flips the sheet content, its detents and the map chrome.

## Feature map

| Feature | Plan | Go |
| --- | --- | --- |
| Catalog / search | Circles segment with search field | — (switch to Plan) |
| Favorites | Favorites segment | Coloured on the map, route goes through them |
| Buys | Buys segment | "Still to Buy" list in the sheet, full list under More |
| Shared Buys | Shop together row (Buys, Prepare) | Live strip under the next stop (where Aoi and Mika are, items with friends) |
| Route / navigation | Preview Route in Prepare | Start card / Next Stop card at the top of the sheet; route pill on the map; All Route Stops under More |
| My Comiket | Profile avatar in the header; Prepare segment | — |
| Event Data | Prepare › Download Before You Go | Offline Readiness card › Manage Event Data |
| Settings | Gear button in the header; Prepare | More › Settings |
| Offline state | Offline pill on the map | Offline pill, or a green "Ready offline" pill; readiness card with an Offline Mode toggle |
| Guest state | Guest banner in the header | Guest banner under the Shared Buys strip |
| Day / hall | Day/Hall control on the map | Day/Hall control on the map |

## Adapting

- iPhone and Duo closed: a real sheet. Plan uses 150pt / medium / large and opens at medium. Go uses 210pt / medium / large and opens at 210pt, which fits the next stop card and the Shared Buys strip and leaves the map dominant. The mode switch sits top-leading, the Day/Hall control top-trailing, status pills on a second row.
- Duo open and iPad: a 380pt floating glass panel at full height on the leading side; the same Plan or Go content, with the mode switch and pills over the map to its right.

## Launch arguments

- `-screen go` opens Go mode (also chosen automatically with `-navigating`).
- `-screen circles|favorites|buys|prep` opens Plan on that segment.
- `-screen myComiket|eventData|settings|catalog` pushes that screen in Plan; `-screen sharedBuys|navigation` pushes it in Go.
- `-detent small|medium|large` sets the starting detent (small maps to the mode's own small detent).
