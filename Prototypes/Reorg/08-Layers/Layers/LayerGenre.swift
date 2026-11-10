import SwiftUI

enum LayerGenre {

    static func genre(forBlock index: Int, in hall: Hall) -> String {
        MockData.circles.first { $0.hall == hall && $0.blockIndex == index }?.genre
            ?? MockData.genres[index % MockData.genres.count]
    }

    static func color(for genre: String) -> Color {
        let index = MockData.genres.firstIndex(of: genre) ?? 0
        return Color(hue: Double(index) / Double(MockData.genres.count), saturation: 0.6, brightness: 0.85)
    }
}
