import SwiftUI

struct HubFilterChips: View {

    @Environment(Harness.self) var harness
    @Binding var selection: HubFilter

    var colorsInUse: [FavoriteColor] {
        FavoriteColor.allCases.filter { harness.favorites.values.contains($0) }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8.0) {
                HubFilterChip(title: "All", isSelected: selection == .all) { selection = .all }
                HubFilterChip(title: "Favorites", symbol: "star.fill", tint: .orange,
                              count: harness.favorites.count, isSelected: selection == .favorites) {
                    selection = .favorites
                }
                ForEach(colorsInUse) { color in
                    HubFilterChip(title: color.name, swatch: color.color,
                                  count: harness.favorites.values.filter { $0 == color }.count,
                                  isSelected: selection == .color(color)) {
                        selection = .color(color)
                    }
                }
                HubFilterChip(title: "Visited", symbol: "checkmark.circle.fill", tint: .green,
                              count: harness.visited.count, isSelected: selection == .visited) {
                    selection = .visited
                }
            }
            .padding(.horizontal, 16.0)
        }
        .scrollIndicators(.hidden)
    }
}
