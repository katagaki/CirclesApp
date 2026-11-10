import SwiftUI

struct SpotlightIndex {

    let harness: Harness
    let settings: SpotlightSettings
    let query: String

    func matches(_ title: String, _ keywords: [String]) -> Bool {
        ([title] + keywords).contains { $0.localizedCaseInsensitiveContains(query) }
    }

    var screens: [Feature] {
        Feature.allCases.filter { $0 != .map && matches($0.title, SpotlightIndex.screenKeywords($0)) }
    }

    static func screenKeywords(_ feature: Feature) -> [String] {
        switch feature {
        case .map: ["hall", "floor"]
        case .catalog: ["catalog", "browse", "genre", "サークル"]
        case .favorites: ["star", "saved", "bookmark", "お気に入り"]
        case .buys: ["shopping", "list", "budget", "money", "買い物"]
        case .sharedBuys: ["friends", "together", "share", "invite", "group"]
        case .navigation: ["navigation", "walk", "path", "directions", "next stop"]
        case .myComiket: ["me", "profile", "account", "participation", "days", "circle.ms"]
        case .eventData: ["download", "storage", "update", "data", "backup"]
        case .settings: ["preferences", "options", "customize", "privacy", "links", "account", "sign out"]
        }
    }

    var circles: [MockCircle] {
        MockData.circles.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.author.localizedCaseInsensitiveContains(query)
                || $0.genre.localizedCaseInsensitiveContains(query) || $0.spaceName.localizedCaseInsensitiveContains(query)
        }
    }

    var actions: [SpotlightAction] {
        var actions: [SpotlightAction] = []
        if harness.isNavigating {
            actions.append(SpotlightAction(id: "endRoute", title: "End route", symbol: "xmark.circle", tint: .red,
                                           keywords: ["stop", "navigation"]) { harness.isNavigating = false })
        } else {
            actions.append(SpotlightAction(id: "startRoute", title: "Start route",
                                           subtitle: "\(harness.routeStops.count) favorites in \(harness.hall.name)",
                                           symbol: "location.north.fill", tint: .blue,
                                           keywords: ["navigate", "walk", "begin"]) {
                harness.routeStep = 1
                harness.isNavigating = true
            })
        }
        actions.append(SpotlightAction(id: "offline", title: harness.isOffline ? "Go online" : "Go offline",
                                       subtitle: harness.isOffline ? "Using downloaded data" : "Use downloaded data only",
                                       symbol: harness.isOffline ? "wifi" : "wifi.slash", tint: .orange,
                                       keywords: ["offline", "online", "network", "airplane"]) { harness.isOffline.toggle() })
        actions.append(SpotlightAction(id: "invite", title: "Invite to Shared Buys", subtitle: "Show a QR code to a friend",
                                       symbol: "qrcode", tint: .purple, keywords: ["share", "friends", "together", "join"],
                                       destination: .sharedBuys) { harness.isSharedBuysActive = true })
        actions.append(SpotlightAction(id: "addBuy", title: "Add to Buys", symbol: "bag.badge.plus", tint: .pink,
                                       keywords: ["shopping", "item", "new"], destination: .buys) {})
        for day in [1, 2] where day != harness.day {
            actions.append(SpotlightAction(id: "day\(day)", title: "Switch to Day \(day)", symbol: "calendar", tint: .indigo,
                                           keywords: ["day", "date"]) { harness.day = day })
        }
        for hall in Hall.allCases where hall != harness.hall {
            actions.append(SpotlightAction(id: hall.rawValue, title: "Show \(hall.name)", symbol: "map", tint: hall.accent,
                                           keywords: ["hall", "map", hall.shortName]) { harness.hall = hall })
        }
        actions.append(SpotlightAction(id: "updates", title: "Check for event data updates", symbol: "arrow.down.circle",
                                       tint: .gray, keywords: ["download", "update"], destination: .eventData) {})
        actions.append(SpotlightAction(id: "backup", title: "Back up to iCloud", symbol: "icloud", tint: .cyan,
                                       keywords: ["backup", "restore", "sync"]) {})
        actions.append(SpotlightAction(id: "webCatalog", title: "Open Web Catalog", symbol: "safari", tint: .blue,
                                       keywords: ["link", "website", "circle.ms"]) {})
        actions.append(SpotlightAction(id: "access", title: "Getting to Tokyo Big Sight", symbol: "tram", tint: .green,
                                       keywords: ["link", "train", "directions", "access"]) {})
        if harness.isGuest {
            actions.append(SpotlightAction(id: "signIn", title: "Sign in with Circle.ms", symbol: "person.crop.circle.badge.checkmark",
                                           tint: .accentColor, keywords: ["login", "account", "guest"]) { harness.isGuest = false })
        } else {
            actions.append(SpotlightAction(id: "signOut", title: "Sign out", symbol: "rectangle.portrait.and.arrow.right",
                                           tint: .red, keywords: ["logout", "account"], destination: .settings) {})
        }
        return actions.filter { matches($0.title, $0.keywords) }
    }

    var toggles: [SpotlightToggle] {
        @Bindable var settings = settings
        @Bindable var harness = harness
        let toggles = [
            SpotlightToggle(id: "offline", title: "Offline Mode", section: "Account", symbol: "wifi.slash",
                            keywords: ["network"], isOn: $harness.isOffline),
            SpotlightToggle(id: "genre", title: "Genre Overlays", section: "Map", symbol: "theatermasks",
                            keywords: ["map", "color"], isOn: $settings.genreOverlays),
            SpotlightToggle(id: "dark", title: "Dark Maps", section: "Map", symbol: "moon",
                            keywords: ["map", "night", "appearance"], isOn: $settings.darkMaps),
            SpotlightToggle(id: "hd", title: "High Resolution Maps", section: "Map", symbol: "square.resize.up",
                            keywords: ["map", "quality", "hd"], isOn: $settings.highResolution),
            SpotlightToggle(id: "space", title: "Show Hall and Block", section: "Circles", symbol: "table.furniture",
                            keywords: ["circle", "display", "space"], isOn: $settings.showSpace),
            SpotlightToggle(id: "day", title: "Show Day", section: "Circles", symbol: "calendar",
                            keywords: ["circle", "display"], isOn: $settings.showDay),
            SpotlightToggle(id: "doubleTap", title: "Double Tap to Visit", section: "Circles", symbol: "hand.tap",
                            keywords: ["visited", "gesture"], isOn: $settings.doubleTapToVisit),
            SpotlightToggle(id: "privacy", title: "Privacy Mode", section: "Privacy", symbol: "eye.slash",
                            keywords: ["hide", "private", "screen"], isOn: $settings.privacyMode)
        ]
        return toggles.filter { matches($0.title, $0.keywords + [$0.section]) }
    }
}
