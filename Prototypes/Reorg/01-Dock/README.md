# 01 Dock

The most familiar shape: a four-tab dock lives inside the sheet itself (Explore, Favorites, Buys, Me), with search pinned at the top of the sheet. The map keeps only map controls: Day/Hall in the middle, a Route button on the right, status pills on the left. Everything that used to hide in the "More" menu moves into the Me tab.

## Feature map

| Feature | Where |
| --- | --- |
| Catalog / search | Explore tab: search field + genre chips + grid |
| Favorites | Favorites tab |
| Buys | Buys tab |
| Shared Buys | Buys tab "Shop together" row, purple dot on the Buys tab while live; Me › Shared Buys |
| Route / navigation | Route button on the map (becomes the live route pill); Me › Route |
| My Comiket | Me tab profile row |
| Event Data, Settings | Me tab |
| Offline state | Offline pill on the map; Offline Mode toggle in Settings |
| Guest state | Guest banner under the search field |
| Day / hall | Day/Hall control on the map |

## Adapting

- iPhone and Duo closed: a real sheet with 170pt / medium / large detents. The small detent still shows search and the dock.
- Duo open and iPad: a 380pt floating glass panel on the leading side with the dock at its bottom.

## Launch arguments

`-screen explore|saved|buys|me` selects the tab.
