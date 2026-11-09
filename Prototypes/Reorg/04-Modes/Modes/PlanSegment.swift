import SwiftUI

enum PlanSegment: String, CaseIterable, Identifiable {
    case circles, favorites, buys, prep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circles: "Circles"
        case .favorites: "Favorites"
        case .buys: "Buys"
        case .prep: "Prepare"
        }
    }
}
