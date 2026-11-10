# 10 Hub

Cut the app down to as few top-level places as possible. The sheet has just two segments, Circles and Buys. A single Start Route button sits beside them and turns into a live next-stop bar once you're walking. Everything personal or app-level lives in one "Me" hub behind the profile avatar on the map.

## Features

| Feature | Where |
| --- | --- |
| Catalog / search | Circles segment: search field, filter chips, grid |
| Favorites | A filter of Circles: All, Favorites, one chip per favorite colour in use, Visited |
| Buys | Buys segment: totals and shopping list |
| Shared Buys | Part of Buys: a "Shopping with Aoi and Mika" row (opens members and progress), assignee avatars on the rows, or a "Shop together" row to start one |
| Route / navigation | Start Route button in the sheet header; while navigating, a blue live bar shows the next stop with Visited and End buttons, and tapping it opens all stops |
| My Comiket | Me hub → profile row |
| Offline Mode | Me hub toggle; Offline pill in the map chrome |
| Event Data, backup | Me hub → Event Data section |
| Map and circle display, links, account | Me hub → App and Account sections (full settings pushed from Map & Circle Display) |
| Guest | Guest banner in the sheet header and the Me hub; the avatar shows a guest figure |
| Day / hall | Day and hall control in the map chrome |

The Me hub is a nested sheet presented from the panel content, never from the map root.

## Sizes

- iPhone and iPhone Duo closed (466pt): sheet with small (170pt), medium and large detents. The small detent still shows the segments, the route action and search. The Me hub stacks over the sheet at the large detent.
- iPhone Duo open and iPad: the same header and content fill the floating glass panel. The avatar sits at the top right of the map and opens Me as a form sheet presented from the panel.

## Launch screens

`-screen favorites` (Circles with the Favorites filter), `-screen buys`, `-screen me` (opens the Me hub).
