# WatchMapPrototype

Standalone watchOS app for evaluating a favorites-first venue companion. Not shippable code.

The app opens on the **route**: one full-screen card per favorite for the selected day, in
block order, driven by the crown. Each card carries the space code at a glance, the hall, the
buy summary, a visited toggle, and a button through to the map. The map is a drill-down, not
the home screen. Scrolling past the last card reaches a menu page with the day picker, the
full favorites list, buys, the map lab, and the widget gallery.

Cards adapt to the Always-On display via `isLuminanceReduced`: when the wrist drops, the
buttons, circle name, and colour wash disappear and only the space code and hall remain.

## Next Stop widget

`RouteWidget` is a WidgetKit extension providing `accessoryRectangular`, `accessoryCircular`,
`accessoryInline`, and `accessoryCorner` renderings of the next unvisited circle on the route.

There is no ActivityKit on watchOS — `ActivityKit.framework` is absent from the watchOS SDK,
so a native watch Live Activity is not possible. The Smart Stack equivalent is a widget plus
RelevanceKit. `NextStopProvider.relevance()` returns date attributes for each event day and a
`CLCircularRegion` around Tokyo Big Sight, so the widget floats up the Smart Stack at the
venue on the right days.

App and widget share visited state through the `group.com.tsubuzaki.circlesproto` app group
(`SharedState`); toggling visited in the app calls `WidgetCenter.reloadTimelines`. The widget
extension carries its own copy of the text database, since it cannot read the host bundle.

## Data

Bundles the C999 demo databases copied from `../../../CirclesGo/app/src/main/assets/demo`
(1.1MB text + 3.7MB images). Favorites and buys are synthesised deterministically from the
catalog, since there is no login.

Read with the raw `SQLite3` C API rather than AXiS — the prototype deliberately has no
dependency on the shipping frameworks.

## Build and run

```bash
xcodegen generate
xcodebuild -project WatchMapPrototype.xcodeproj -scheme WatchMapPrototype \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' build
```

`WatchMapPrototype.xcodeproj` is generated and gitignored; run `xcodegen generate` after
cloning.

## Launch overrides

Jump straight to a screen without tapping through:

```bash
xcrun simctl launch <udid> com.tsubuzaki.circlesproto.watchkitapp -Prototype.Launch focus
```

Accepted values: `step`, `focus`, `panZoom`, `overview`, `directions`, `favorites`, `buys`, `lab`,
`widgets`. Omit it entirely to get the normal route-first launch.

Additional debug arguments, since the crown and taps cannot be driven headlessly:

- `-Prototype.RouteSelection menu` opens the route's menu page
- `-Prototype.StepIndex <n>` seeds which circle `step` starts on
- `-Prototype.ShowMapPicker YES` opens the map picker on launch
- `-Prototype.RouteIndex <n>` opens the route on card `n`
- `-Prototype.VisitFirst <n>` marks the first `n` favorites of the day visited
- `-Prototype.SelfTest YES` prints app-group status and tap hit-test assertions to the console

## Colour

Chrome follows the app accent colour (`AccentColor` is copied from `App/Assets.xcassets`).
Favourite colours are catalog data, not theme, so they keep their exact `WebCatalogColor`
values — but they are only ever used as **fills** paired with `FavoriteColor.foreground`,
matching how the iOS app uses `backgroundColor()`/`foregroundColor()`. Never as text on a dark
background: `blue` is `rgb(0, 0, 1)` and is unreadable that way on an always-dark watch screen.

## Approaches

| Key | Idea |
| --- | --- |
| `step` | Crown steps circle to circle, tap any space to select it, hall picker top-left |
| `focus` | Auto-centred crop on the target space; crown widens the visible context |
| `panZoom` | Full hall map, drag to pan, crown to zoom — the naive port of the iOS map |
| `overview` | Whole hall fitted to screen, favorites as dots, crown steps between them |
| `directions` | No navigation at all — space number, hall, and a locator thumbnail |
