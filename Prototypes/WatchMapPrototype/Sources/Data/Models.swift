import CoreGraphics
import Foundation
import SwiftUI

enum LayoutType: Int {
    case unknown = 0
    case aOnLeft = 1
    case aOnBottom = 2
    case aOnRight = 3
    case aOnTop = 4
}

struct EventDay: Identifiable, Hashable {
    let id: Int
    let year: Int
    let month: Int
    let day: Int

    var shortLabel: String { "Day \(id)" }
    var dateLabel: String { "\(month)/\(day)" }
}

struct HallMap: Identifiable, Hashable {
    let id: Int
    let name: String
    let filename: String
    let size: CGSize
}

struct MapBlock: Identifiable, Hashable {
    let id: Int
    let name: String
}

struct SpaceLayout: Hashable {
    let blockID: Int
    let spaceNumber: Int
    let position: CGPoint
    let layoutType: LayoutType
    let mapID: Int
}

struct CatalogCircle: Identifiable, Hashable {
    let id: Int
    let day: Int
    let blockID: Int
    let spaceNumber: Int
    let spaceNumberSuffix: Int
    let genreID: Int
    let name: String
    let penName: String

    var spaceNumberCombined: String {
        var combined = String(format: "%02d", spaceNumber)
        switch spaceNumberSuffix {
        case 0: combined += "a"
        case 1: combined += "b"
        case 2: combined += "c"
        default: break
        }
        return combined
    }
}

enum FavoriteColor: Int, CaseIterable {
    case orange = 1
    case pink = 2
    case yellow = 3
    case green = 4
    case cyan = 5
    case purple = 6
    case blue = 7
    case lime = 8
    case red = 9

    var color: Color {
        switch self {
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.29)
        case .pink: return Color(red: 1.0, green: 0.0, blue: 1.0)
        case .yellow: return Color(red: 1.0, green: 0.97, blue: 0.0)
        case .green: return Color(red: 0.0, green: 0.71, blue: 0.29)
        case .cyan: return Color(red: 0.0, green: 0.71, blue: 1.0)
        case .purple: return Color(red: 0.61, green: 0.32, blue: 0.61)
        case .blue: return Color(red: 0.0, green: 0.0, blue: 1.0)
        case .lime: return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .red: return Color(red: 1.0, green: 0.0, blue: 0.0)
        }
    }

    var name: String {
        switch self {
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .cyan: return "Light Blue"
        case .purple: return "Purple"
        case .blue: return "Blue"
        case .lime: return "Light Green"
        case .red: return "Red"
        }
    }
}

struct Favorite: Identifiable, Hashable {
    let circle: CatalogCircle
    let color: FavoriteColor
    let blockName: String
    let mapID: Int

    var id: Int { circle.id }
    var spaceLabel: String { "\(blockName)\(circle.spaceNumberCombined)" }
}

struct BuyItem: Identifiable, Hashable {
    let id: String
    let circleID: Int
    let name: String
    let cost: Int
    var isBought: Bool
}
