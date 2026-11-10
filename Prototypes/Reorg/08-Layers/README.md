# 08 Layers

Everything is a map layer. A row of glass layer chips across the top of the map turns Favorites, Buys, Route, Friends, Visited and Genres on and off; turning a layer on draws it on the hall map and focuses it, so the sheet shows that layer's list. With no layer focused the sheet is the catalog.

## Chips

- Off: plain glass chip. Tap to turn the layer on and focus it.
- On: coloured icon with an underline. Its overlay stays on the map, dimmed while another layer is focused. Tap to focus it again.
- Focused: chip filled with the layer colour, overlay at full strength, sheet header shows the layer. Tap the focused chip to turn the layer off. The header's eye button hides the layer and its grid button goes back to the catalog with the layer still drawn.

## Features

| Feature | Where |
| --- | --- |
| Catalog / search | Sheet with no focused layer (search field + genre chips + grid) |
| Favorites | Favorites layer: coloured star markers on the map, favorites grid in the sheet |
| Buys | Buys layer: bag markers with item counts, Buys list in the sheet |
| Shared Buys | Friends layer: Aoi and Mika's avatars on the map, Shared Buys members and assignments in the sheet (onboarding when not shared) |
| Route / navigation | Route layer: route line and numbered stops, Route view in the sheet; `-navigating` focuses it and the map chrome shows the live route pill |
| Visited | Visited layer: check markers, visited / still to visit list |
| Genres | Genres layer: blocks shaded by genre, circles grouped by genre |
| My Comiket, Event Data, Settings | Profile avatar in the sheet header pushes a Me page |
| Offline | Offline pill in the map chrome; Offline Mode toggle in Settings |
| Guest | Guest banner under the sheet header and on the Me page; avatar shows a guest figure |
| Day / hall | Day and hall control in the map chrome |

## Sizes

- iPhone and iPhone Duo closed (466pt): the sheet sits over the map with small, medium and large detents. The chips scroll horizontally and scroll the focused chip into view. The hall map recentres in the area above the sheet, so it gets more room at the small detent.
- iPhone Duo open and iPad: the sheet becomes the floating glass panel on the leading side. Day/hall, status pills and layer chips sit over the map to the panel's right, and the overlays draw on the full-height map.

## Launch screens

`-screen favorites | buys | route | friends | visited | genres` turns that layer on and focuses it.
