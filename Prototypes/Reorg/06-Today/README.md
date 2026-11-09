# 06 Today

The sheet over the map is a "what now?" feed: a short stack of cards, ordered by what matters at this moment of the event
day (next stop while navigating, guest prompt, offline readiness when offline, live Shared Buys, today's favorites, budget).
Each card answers one question at a glance and has a "See All" that pushes the full feature. Search and the profile menu
sit in a compact header so the feed stays about the day, not the app.

## Feature map

| Feature | Where |
| --- | --- |
| Catalog / search | Search button in the header → full catalog with search field and genre chips |
| Favorites | "Favorites Today" card (count in the current hall, cut strip) → See All |
| Buys | "Buys" card (budget left, items to buy) → See All |
| Shared Buys | "Shared Buys" card (member progress when live, Start otherwise) → See All |
| Route / navigation | "Route" card: Start CTA, or the next stop with a check-off button while navigating → See All; route pill on the map |
| My Comiket | Profile avatar menu in the header |
| Event data | "Event Data" card (download / offline readiness) → See All; also in the avatar menu |
| Settings | Profile avatar menu |
| Offline state | Offline pill on the map; the Event Data card jumps near the top and turns orange |
| Guest state | GuestBanner card near the top; avatar menu offers Sign In |
| Day / hall | Day/Hall control on the map; the header shows the date and the cards follow the selection |

## Layouts

- **iPhone / Duo closed (sheet):** compact detent shows the header and only the single most relevant card (the next stop
  while navigating, otherwise guest prompt, offline state, live Shared Buys or the route CTA). Medium/large show the feed.
  Opening anything from compact raises the sheet.
- **Duo open / iPad (panel):** the same feed in the 380pt floating panel, always showing every card; pushed screens stay in
  the panel's navigation stack, the map keeps its own chrome to the right.

## `-screen` values

`search`, `catalog`, `favorites`, `buys`, `sharedBuys`, `route` (or `navigation`), `myComiket`, `eventData`, `settings`.
`-detent small` opens the single-card compact state.
