import SwiftUI

enum Feature: String, CaseIterable, Identifiable, Hashable {
    case map, catalog, favorites, buys, sharedBuys, navigation, myComiket, eventData, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .map: "Map"
        case .catalog: "Circles"
        case .favorites: "Favorites"
        case .buys: "Buys"
        case .sharedBuys: "Shared Buys"
        case .navigation: "Route"
        case .myComiket: "My Comiket"
        case .eventData: "Event Data"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .map: "map"
        case .catalog: "square.grid.2x2"
        case .favorites: "star"
        case .buys: "bag"
        case .sharedBuys: "person.2"
        case .navigation: "point.bottomleft.forward.to.point.topright.scurvepath"
        case .myComiket: "person.crop.circle"
        case .eventData: "externaldrive"
        case .settings: "gearshape"
        }
    }

    var tint: Color {
        switch self {
        case .map: .teal
        case .catalog: .indigo
        case .favorites: .orange
        case .buys: .pink
        case .sharedBuys: .purple
        case .navigation: .blue
        case .myComiket: .green
        case .eventData: .gray
        case .settings: .gray
        }
    }
}
