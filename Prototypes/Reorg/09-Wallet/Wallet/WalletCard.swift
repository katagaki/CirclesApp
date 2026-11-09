import SwiftUI

enum WalletCard: String, CaseIterable, Identifiable, Hashable {
    case catalog, favorites, buys, sharedBuys, navigation, myComiket, settings

    var id: String { rawValue }

    var feature: Feature { Feature(rawValue: rawValue) ?? .catalog }

    var title: String {
        self == .settings ? "Settings & Data" : feature.title
    }

    var symbol: String { feature.symbol }

    var colors: [Color] {
        switch self {
        case .catalog: [Color(red: 0.36, green: 0.33, blue: 0.86), Color(red: 0.52, green: 0.42, blue: 0.95)]
        case .favorites: [Color(red: 0.98, green: 0.52, blue: 0.18), Color(red: 1.0, green: 0.7, blue: 0.3)]
        case .buys: [Color(red: 0.92, green: 0.24, blue: 0.47), Color(red: 1.0, green: 0.45, blue: 0.6)]
        case .sharedBuys: [Color(red: 0.55, green: 0.27, blue: 0.82), Color(red: 0.72, green: 0.45, blue: 0.95)]
        case .navigation: [Color(red: 0.0, green: 0.45, blue: 0.95), Color(red: 0.2, green: 0.65, blue: 1.0)]
        case .myComiket: [Color(red: 0.1, green: 0.62, blue: 0.45), Color(red: 0.3, green: 0.78, blue: 0.55)]
        case .settings: [Color(red: 0.35, green: 0.38, blue: 0.43), Color(red: 0.52, green: 0.55, blue: 0.6)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    init?(screen: String) {
        if screen == Feature.eventData.rawValue {
            self = .settings
        } else if screen == Feature.map.rawValue {
            self = .catalog
        } else {
            self.init(rawValue: screen)
        }
    }
}
