# 02 Launcher

The sheet over the map opens on a launcher instead of a list. Pulled down, it is a search field and a row of round shortcuts (Circles, Favorites, Buys, Route, Me). Pulled up, it becomes a grid of feature tiles with live subtitles, grouped by when you need them: Plan, At the Event, Account & Data. Every tile pushes its screen inside the sheet's navigation stack, so nothing hides behind a "More" menu.

## Feature map

| Feature | Where |
| --- | --- |
| Catalog / search | Search field at the top of the sheet (results replace the tiles), Circles shortcut and tile |
| Favorites | Favorites shortcut and tile ("12 favorites · 6 today") |
| Buys | Buys shortcut and tile ("¥6,200 · 4 left") |
| Shared Buys | At the Event tile ("Shared with Aoi and Mika", live dot), also from Buys |
| Route / navigation | Route shortcut and tile ("Next stop 東A-25a"); next stop card on top of the tiles while navigating; route pill on the map |
| My Comiket | Profile avatar next to the search field, Me shortcut, My Comiket tile |
| Event Data | Account & Data tile (shows offline / up to date) |
| Settings | Account & Data tile |
| Offline state | Offline pill on the map, Event Data tile subtitle |
| Guest state | Guest banner under the shortcuts / above the tiles |
| Day / hall | Day/Hall control on the map |

## Adapting

- iPhone and Duo closed (466pt): a real sheet with three detents. The small detent (176pt) shows only search and shortcuts; medium and large show the tile grid. Searching or opening a shortcut from the small detent raises the sheet to medium.
- Duo open (951pt) and iPad: the launcher is a 380pt floating glass panel on the leading side and always shows the full tile grid (two columns); the map and its chrome sit to the right.

## Launch arguments

- `-screen catalog|favorites|buys|sharedBuys|navigation|myComiket|eventData|settings` pushes that screen on top of the launcher.
- `-detent small|medium|large` sets the starting detent (small maps to the launcher's 176pt detent).
