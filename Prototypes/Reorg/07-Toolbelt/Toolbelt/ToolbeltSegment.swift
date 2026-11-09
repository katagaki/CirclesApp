import Foundation

enum ToolbeltSegment: String, CaseIterable, Identifiable {
    case circles, favorites, buys

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circles: "Circles"
        case .favorites: "Favorites"
        case .buys: "Buys"
        }
    }
}
