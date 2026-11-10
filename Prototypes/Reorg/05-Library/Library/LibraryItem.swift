import SwiftUI

enum LibraryItem: Hashable, Identifiable {
    case allCircles, genres, search
    case favorites, favoriteColor(FavoriteColor), buys, sharedBuys
    case route, visited
    case myComiket, eventData, settings

    static let browse: [LibraryItem] = [.allCircles, .genres, .search]
    static let atTheEvent: [LibraryItem] = [.route, .visited]
    static let you: [LibraryItem] = [.myComiket, .eventData, .settings]
    static let compact: [LibraryItem] = [.favorites, .buys, .route, .sharedBuys]

    var id: String { screenName }

    var screenName: String {
        switch self {
        case .allCircles: "circles"
        case .genres: "genres"
        case .search: "search"
        case .favorites: "favorites"
        case .favoriteColor(let color): "favorites-\(color)"
        case .buys: "buys"
        case .sharedBuys: "sharedBuys"
        case .route: "route"
        case .visited: "visited"
        case .myComiket: "myComiket"
        case .eventData: "eventData"
        case .settings: "settings"
        }
    }

    init?(screen: String) {
        let all: [LibraryItem] = LibraryItem.browse + [.favorites, .buys, .sharedBuys]
            + FavoriteColor.allCases.map { .favoriteColor($0) } + LibraryItem.atTheEvent + LibraryItem.you
        guard let item = all.first(where: { $0.screenName == screen }) else { return nil }
        self = item
    }

    var title: String {
        switch self {
        case .allCircles: "All Circles"
        case .genres: "Genres"
        case .search: "Search"
        case .favorites: "Favorites"
        case .favoriteColor(let color): color.name
        case .buys: "Buys"
        case .sharedBuys: "Shared Buys"
        case .route: "Route"
        case .visited: "Visited"
        case .myComiket: "My Comiket"
        case .eventData: "Event Data"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .allCircles: "square.grid.2x2"
        case .genres: "theatermasks"
        case .search: "magnifyingglass"
        case .favorites: "star"
        case .favoriteColor: "square.fill"
        case .buys: "bag"
        case .sharedBuys: "person.2"
        case .route: Feature.navigation.symbol
        case .visited: "checkmark.circle"
        case .myComiket: "person.crop.circle"
        case .eventData: "externaldrive"
        case .settings: "gearshape"
        }
    }

    var tint: Color {
        switch self {
        case .allCircles: .indigo
        case .genres: .teal
        case .search: .gray
        case .favorites: .orange
        case .favoriteColor(let color): color.color
        case .buys: .pink
        case .sharedBuys: .purple
        case .route: .blue
        case .visited: .green
        case .myComiket: .green
        case .eventData, .settings: .gray
        }
    }
}
