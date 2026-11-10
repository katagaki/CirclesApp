# 09 Wallet

Every feature is a colourful card in a Wallet-style stack inside the sheet. Each card's header carries a live summary (circles on today's day, favorites count, Buys total, who you're shopping with, next route stop, profile, offline state), so the stack doubles as a dashboard. Tap a card and it grows to fill the sheet with the full feature; the other cards tuck into a row of small cards at the bottom for one-tap switching, and the chevron folds it back into the stack.

## Features

| Feature | Card |
| --- | --- |
| Catalog / search | Circles: search field, genre chips, grid |
| Favorites | Favorites: colour counts in the card, grouped grid inside |
| Buys | Buys: total, left to buy and progress in the card, shopping list inside |
| Shared Buys | Shared Buys: member avatars or "Not shared", members and assignments or onboarding inside |
| Route / navigation | Route: stop count or live next stop, Route view inside; the map chrome shows the live route pill |
| My Comiket | My Comiket: profile and participation days |
| Event Data, backup, display settings, links, account | Settings & Data card (Event Data is pushed from it) |
| Offline | Offline pill in the map chrome; the Settings & Data card shows "Offline" in its header |
| Guest | Guest banner above the stack; the My Comiket card reads "Guest" |
| Day / hall | Day and hall control in the map chrome |

## Sizes

- iPhone and iPhone Duo closed (466pt): sheet with compact (220pt), medium and large detents. At the compact detent the cards collapse to just their top edges, like a wallet in a pocket; at medium every header with its summary shows, and at large the cards spread out further. Expanding a card from the compact detent raises the sheet to medium.
- iPhone Duo open and iPad: the same stack lives in the floating glass panel at full height. An expanded card fills the panel above the tucked row, with the map to its right.

## Launch screens

`-screen catalog | favorites | buys | sharedBuys | navigation | myComiket | settings` expands that card (`eventData` opens Settings & Data). The sheet opens at the large detent unless `-detent` is given.
