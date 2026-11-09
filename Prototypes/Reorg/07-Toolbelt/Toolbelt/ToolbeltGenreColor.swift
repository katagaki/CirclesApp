import SwiftUI

enum ToolbeltGenreColor {
    static func color(for index: Int) -> Color {
        Color(hue: Double(index) / Double(MockData.genres.count), saturation: 0.5, brightness: 0.92)
    }
}
