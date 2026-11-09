# 03 Spotlight

Search first. The sheet over the map has one big search field and no tabs or menus: every screen, action and setting in the app is findable by typing its name (or a synonym like "money", "friends", "backup"). With an empty query the sheet offers suggestion chips, recent circles and a few "Jump to" shortcuts that carry live status.

## Feature map

| Feature | Where |
| --- | --- |
| Catalog / search | Type a circle, author, genre or space; Circles section in results; Circles chip |
| Favorites, Buys | Chips; "Buys" in Jump To (¥ total · items left); typing their name or synonyms |
| Shared Buys | Chip; Jump To row ("Shared with Aoi and Mika"); "Invite to Shared Buys" action |
| Route / navigation | Chip; Jump To shows "Plan a route" or the next stop while navigating; "Start route" / "End route" actions; route pill on the map |
| My Comiket | Profile avatar inside the search field; chip; "me", "profile", "participation" |
| Event Data | Chip; Jump To row (offline / up to date); "Check for event data updates" action |
| Settings | Chip opens the full screen; each toggle (Dark Maps, Privacy Mode, Offline Mode, …) appears inline in results and works in place |
| Offline state | Offline pill on the map; Event Data row subtitle; "Go offline / Go online" action |
| Guest state | Guest banner at the top of the sheet; "Sign in with Circle.ms" action |
| Day / hall | Day/Hall control on the map; "Switch to Day 2" and "Show West 1–2" actions |

Results are grouped as Screens, Actions, Settings and Circles.

## Adapting

- iPhone and Duo closed: a real sheet with 150pt / medium / large detents. The small detent shows only the search field and chips; typing raises the sheet to medium. While a query is active the chips are hidden to give results the room.
- Duo open and iPad: a 380pt floating glass panel; the chips stay visible under the field even while results are shown, so you can switch to a screen without clearing the query.

## Launch arguments

- `-query <text>` prefills the search (e.g. `-query off`, `-query share`, `-query map`, `-query neko`).
- `-screen catalog|favorites|buys|sharedBuys|navigation|myComiket|eventData|settings` pushes that screen.
- `-detent small|medium|large` sets the starting detent.
