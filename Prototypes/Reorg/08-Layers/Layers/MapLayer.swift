import SwiftUI

enum MapLayer: String, CaseIterable, Identifiable, Hashable {
    case favorites, buys, route, friends, visited, genres

    var id: String { rawValue }

    var title: String {
        switch self {
        case .favorites: "Favorites"
        case .buys: "Buys"
        case .route: "Route"
        case .friends: "Friends"
        case .visited: "Visited"
        case .genres: "Genres"
        }
    }

    var symbol: String {
        switch self {
        case .favorites: "star.fill"
        case .buys: "bag.fill"
        case .route: "point.bottomleft.forward.to.point.topright.scurvepath"
        case .friends: "person.2.fill"
        case .visited: "checkmark.circle.fill"
        case .genres: "theatermasks.fill"
        }
    }

    var tint: Color {
        switch self {
        case .favorites: .orange
        case .buys: .pink
        case .route: .blue
        case .friends: .purple
        case .visited: .green
        case .genres: .teal
        }
    }
}
