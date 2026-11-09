import Foundation

enum TodayCardKind: String, Identifiable {
    case guest, route, sharedBuys, favorites, buys, readiness

    var id: String { rawValue }

    static func ordered(for harness: Harness) -> [TodayCardKind] {
        var kinds: [TodayCardKind] = []
        if harness.isNavigating { kinds.append(.route) }
        if harness.isGuest { kinds.append(.guest) }
        if harness.isOffline { kinds.append(.readiness) }
        if harness.isSharedBuysActive { kinds.append(.sharedBuys) }
        if !harness.isNavigating { kinds.append(.route) }
        kinds += [.favorites, .buys]
        if !harness.isSharedBuysActive { kinds.append(.sharedBuys) }
        if !harness.isOffline { kinds.append(.readiness) }
        return kinds
    }
}
