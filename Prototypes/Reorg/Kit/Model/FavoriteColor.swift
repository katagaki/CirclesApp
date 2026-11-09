import SwiftUI

enum FavoriteColor: Int, CaseIterable, Identifiable, Hashable {
    case orange = 1, pink, yellow, green, cyan, purple, blue, lime, red

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .orange: Color(red: 1.0, green: 0.58, blue: 0.29)
        case .pink: Color(red: 1.0, green: 0.0, blue: 1.0)
        case .yellow: Color(red: 1.0, green: 0.97, blue: 0.0)
        case .green: Color(red: 0.0, green: 0.71, blue: 0.29)
        case .cyan: Color(red: 0.0, green: 0.71, blue: 1.0)
        case .purple: Color(red: 0.61, green: 0.32, blue: 0.61)
        case .blue: Color(red: 0.0, green: 0.0, blue: 1.0)
        case .lime: Color(red: 0.0, green: 1.0, blue: 0.0)
        case .red: Color(red: 1.0, green: 0.0, blue: 0.0)
        }
    }

    var name: String {
        switch self {
        case .orange: "Orange"
        case .pink: "Pink"
        case .yellow: "Yellow"
        case .green: "Green"
        case .cyan: "Light Blue"
        case .purple: "Purple"
        case .blue: "Blue"
        case .lime: "Light Green"
        case .red: "Red"
        }
    }
}
