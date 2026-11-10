# 07 Toolbelt

Map-first: everything that changes the map or the trip lives on a vertical glass tool rail on the trailing edge of the map,
like Apple Maps' controls. The sheet is only for browsing (Circles / Favorites / Buys with one search field), so it never has
to carry menus. A tool either changes the map in place (Day/Hall, Layers) or temporarily swaps the sheet for its screen,
with a close button that returns to browsing.

## Feature map

| Feature | Where |
| --- | --- |
| Catalog / search | Sheet: search field + Circles segment (typing jumps to Circles) |
| Favorites | Sheet: Favorites segment |
| Buys | Sheet: Buys segment |
| Day / hall | Rail, top: "DAY n / 東1–3" menu with day and hall pickers |
| Route / navigation | Rail: Route tool swaps the sheet to the route screen (start / stops / end); green dot + map pill while live |
| Shared Buys | Rail: Shared Buys tool swaps the sheet to the shared list; green dot while a list is live |
| Map layers | Rail: Layers menu toggles Favorites, Visited and Genre Colors on the map (icon fills when not default) |
| My Comiket / Event Data / Settings | Rail, bottom: Me (profile avatar) swaps the sheet to a short Me list |
| Offline state | Offline pill at the top leading corner of the map; Event Data row says "Offline · on device" |
| Guest state | Gray question-mark avatar on the rail; GuestBanner under the sheet header and in Me |

## Layouts

- **iPhone / Duo closed (sheet):** compact detent shows just the search field and segments; opening a tool, typing or
  opening a circle raises the sheet to medium. The rail sits under the status bar on the trailing edge, above the medium
  detent.
- **Duo open / iPad (panel):** the browsing panel floats on the leading edge, the rail stays on the map's trailing edge,
  and tool screens replace the panel's content with the same close button.

## `-screen` values

Browsing segments: `circles`, `favorites`, `buys`. Tools: `route`, `sharedBuys`, `me`. Inside Me: `myComiket`, `eventData`,
`settings`. `-detent small` opens the compact sheet. The Layers menu can't be opened from a launch argument.
