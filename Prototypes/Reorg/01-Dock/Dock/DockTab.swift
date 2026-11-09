import SwiftUI

enum DockTab: String, CaseIterable, Identifiable {
    case explore, saved, buys, me

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explore: "Explore"
        case .saved: "Favorites"
        case .buys: "Buys"
        case .me: "Me"
        }
    }

    var symbol: String {
        switch self {
        case .explore: "square.grid.2x2.fill"
        case .saved: "star.fill"
        case .buys: "bag.fill"
        case .me: "person.crop.circle.fill"
        }
    }
}
