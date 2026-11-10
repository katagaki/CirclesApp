# 05 Library

The sheet over the map is a grouped, Files/Mail-style library: every feature is a row with a live count or badge, so the
whole app is one scroll away and nothing hides behind a "More" menu. The map stays in charge of where you are (day, hall,
offline state, live route); the library is in charge of what you have.

## Feature map

| Feature | Where |
| --- | --- |
| Catalog / search | Search field at the top of the sheet (results replace the list inline); Browse › All Circles, Genres, Search |
| Favorites | My Lists › Favorites, plus one nested row per favorite color in use |
| Buys | My Lists › Buys (badge: items left) |
| Shared Buys | My Lists › Shared Buys (member avatars when active, "Start" otherwise) |
| Route / navigation | At the Event › Route (live "n/m" badge); route status pill on the map while navigating |
| Visited | At the Event › Visited |
| My Comiket | You › My Comiket (avatar, or "Guest" badge) |
| Event data | You › Event Data (cloud check, or orange "Offline" badge) |
| Settings | You › Settings |
| Offline state | Offline pill on the map + Event Data badge |
| Guest state | GuestBanner at the top of the library; "Guest" badge on My Comiket |
| Day / hall | Day/Hall control on the map |

## Layouts

- **iPhone / Duo closed (sheet):** compact detent shows the search field and the four most used rows (Favorites, Buys,
  Route, Shared Buys); medium/large show the full grouped list. Opening a row or typing in compact raises the sheet.
- **Duo open / iPad portrait (panel narrower than 520pt):** same navigation stack as the sheet, in the floating panel.
- **iPad landscape (panel ~560pt):** the panel widens and splits: library list on the left (selected row highlighted),
  the selected content with its own navigation stack on the right.

## `-screen` values

`circles`, `genres`, `search`, `favorites`, `favorites-<color>` (e.g. `favorites-orange`, `favorites-pink`), `buys`,
`sharedBuys`, `route`, `visited`, `myComiket`, `eventData`, `settings`. On the sheet the row is pushed; in the split panel
it is selected. `-detent small` opens the compact library.
