import SwiftUI

enum ToolbeltTool: String, Identifiable {
    case route, sharedBuys, me

    var id: String { rawValue }

    var title: String {
        switch self {
        case .route: "Route"
        case .sharedBuys: "Shared Buys"
        case .me: "Me"
        }
    }

    var symbol: String {
        switch self {
        case .route: Feature.navigation.symbol
        case .sharedBuys: "person.2.fill"
        case .me: "person.crop.circle"
        }
    }
}
