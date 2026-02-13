# iOS to Android Refactor Progress Summary

## Overview

The Android app (CirclesGo) is a Jetpack Compose rewrite of the iOS CiRCLES app, which is a Comiket circle discovery and management tool. The refactor has made **substantial progress** — the core architecture and most major features have been ported.

---

## Architecture Mapping

| Aspect | iOS | Android |
|--------|-----|---------|
| UI Framework | SwiftUI | Jetpack Compose (Material3) |
| State Management | `@Observable` macro | Kotlin `StateFlow` |
| DI | SwiftUI `@Environment` | Manual constructor injection |
| Persistence | SwiftData + SQLite | SharedPreferences + SQLite |
| Secure Storage | Keychain (KeychainAccess) | EncryptedSharedPreferences |
| Concurrency | Swift Actors + async/await | Kotlin Coroutines + Dispatchers |
| Navigation | Enum-based `UnifiedPath` | Enum-based `UnifiedPath` (mirrored) |

---

## Feature Parity Checklist

### Fully Ported

- **OAuth2 Authentication** — Login flow, token storage, token refresh, deep link callback
- **Event Management** — Event fetching, active event selection, participation tracking
- **Database Management** — SQLite download, ZIP extraction, text + image DB handling, progress UI
- **Circle Catalog** — Search, genre/block/date/map filtering, grid and list views (3 grid sizes, 2 list densities)
- **Interactive Map** — Pan/zoom, map image layer, layout layer, favorites layer, highlight layer, popover layer
- **Favorites** — Add/remove, 9-color coding, server sync, local cache fallback, color-grouped views
- **Visit Tracking** — Mark circles visited, local persistence
- **Circle Detail View** — Full circle info, external links (Twitter, Pixiv, CircleMS, website)
- **State Management Classes** — All core state objects ported: `Authenticator`, `Events`, `FavoritesState`, `CatalogCache`, `Mapper`, `Unifier`, `Oasis`, `UserSelections`
- **Database Tables** — All 8 entity models: `ComiketCircle`, `ComiketBlock`, `ComiketGenre`, `ComiketDate`, `ComiketMap`, `ComiketLayout`, `ComiketEvent`, `ComiketCircleExtendedInformation`
- **API Layer** — All Circle.ms API endpoints: User info, events, favorites CRUD, web catalog
- **Dark Mode** — Map color inversion in dark mode, Material3 theming
- **Display Mode Switching** — Grid/List toggle, grid size options, list density options

### Partially Ported / Differences

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| **Navigation Model** | Bottom sheet + sidebar (iPad) | Bottom sheet only | No tablet-specific sidebar layout |
| **Device Adaptation** | iPhone vs iPad layouts | Single layout | iPad/tablet layout not implemented |
| **Image Caching** | In-memory + disk + WebP decode | In-memory maps from SQLite | No standalone disk cache or WebP conversion |
| **My Comiket View** | Profile section, event covers, participation UI, notification settings | Minimal | My view partially stubbed |
| **More/Settings View** | DB admin, licenses, settings | Minimal | Settings UI not fully implemented |
| **Circle Detail Toolbar** | Prev/Next navigation, "Show on Map" | Basic detail only | Missing prev/next and show-on-map from detail |

### Not Yet Ported

| iOS Feature | Description |
|-------------|-------------|
| **Notifications** | Event participation notifications per day (`MyEventNotifierSheet`) |
| **Translation** | Built-in iOS translation integration (`TranslateButton`) |
| **Privacy Mode** | Content masking view modifier |
| **TipKit Integration** | Double-tap visit tip |
| **Safari/Custom Tabs** | In-app browser (dependency imported but not wired) |
| **View Modifier System** | iOS has 15+ custom view modifiers (`AdaptiveGlass`, `CircleContextMenu`, `FastDoubleTap`, etc.) — Android uses inline Compose modifiers |
| **Namespace Animations** | Shared element transitions between catalog and detail |
| **Context Menus** | Long-press actions on circles |
| **Orientation Tracking** | Device orientation class |
| **Favorite Popover** | Color picker popover for favorites |
| **Map Visited Layer** | Visited circles overlay on map |
| **Login Feature Hero** | Feature showcase cards on login (partially done — 3 cards exist) |
| **Sidebar Position Toggle** | Leading/trailing sidebar preference |
| **Localization** | String localization resources |
| **Tests** | No unit or UI tests |

---

## File Count Comparison

| Category | iOS | Android |
|----------|-----|---------|
| Total source files | ~110+ | ~93 |
| View/UI files | ~60+ | ~24 |
| State/ViewModel files | ~13 | ~9 |
| Database files | ~12 | ~18 |
| API/Network files | ~14 | ~14 |
| Shared components | ~17 | ~3 |

The biggest gap is in **UI components** — the iOS app has significantly more reusable shared components (17 vs 3) and more polished view files (60+ vs 24).

---

## Summary

**Estimated progress: ~70-75% complete.** The core architecture, data layer, networking, and primary user flows are fully ported. The remaining work is primarily:

1. **UI polish** — More shared components, context menus, animations, popovers
2. **Secondary screens** — My Comiket, Settings/More, DB admin
3. **Map enhancements** — Visited layer, show-on-map from detail
4. **Platform features** — Notifications, in-app browser, privacy mode
5. **Tablet support** — Sidebar layout for larger screens
6. **Quality** — Localization, tests, error handling improvements