import Foundation

enum HubSegment: String, CaseIterable, Identifiable {
    case circles, buys

    var id: String { rawValue }

    var title: String {
        switch self {
        case .circles: "Circles"
        case .buys: "Buys"
        }
    }
}
