import SwiftUI

@Observable
final class Harness {

    var isGuest: Bool
    var isOffline: Bool
    var isNavigating: Bool
    var isSharedBuysActive: Bool
    var isHarnessHidden: Bool
    var day: Int = 1
    var hall: Hall = .east123
    var favorites: [Int: FavoriteColor] = MockData.initialFavorites
    var buys: [BuyItem] = MockData.initialBuys
    var visited: Set<Int> = [1000, 1012]
    var routeStep: Int = 1
    var selectedCircle: MockCircle?
    var searchText: String = ""
    let launchScreen: String?
    let launchDetent: String?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        isGuest = arguments.contains("-guest")
        isOffline = arguments.contains("-offline")
        isNavigating = arguments.contains("-navigating")
        isSharedBuysActive = arguments.contains("-sharedBuys") || arguments.contains("-navigating")
        isHarnessHidden = arguments.contains("-hideHarness")
        launchScreen = Harness.value(after: "-screen", in: arguments)
        launchDetent = Harness.value(after: "-detent", in: arguments)
        if let id = Harness.value(after: "-circle", in: arguments).flatMap(Int.init) {
            selectedCircle = MockData.circle(id)
        }
    }

    static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    var circlesForSelection: [MockCircle] {
        MockData.circles.filter { $0.day == day }
    }

    var favoriteCircles: [MockCircle] {
        MockData.circles.filter { favorites[$0.id] != nil }
    }

    var routeStops: [MockCircle] {
        favoriteCircles.filter { $0.hall == hall && $0.day == day }
            .sorted { ($0.blockIndex, $0.slotIndex) < ($1.blockIndex, $1.slotIndex) }
    }

    var nextStop: MockCircle? {
        let stops = routeStops
        guard !stops.isEmpty else { return nil }
        return stops[min(routeStep, stops.count - 1)]
    }

    var buysTotal: Int { buys.reduce(0) { $0 + $1.price } }
    var buysRemaining: Int { buys.filter { !$0.isBought }.count }

    func toggleFavorite(_ circle: MockCircle) {
        if favorites[circle.id] == nil {
            favorites[circle.id] = .orange
        } else {
            favorites[circle.id] = nil
        }
    }

    func detent(default fallback: PresentationDetent) -> PresentationDetent {
        switch launchDetent {
        case "small": .height(120)
        case "medium": .medium
        case "large": .large
        default: fallback
        }
    }
}
