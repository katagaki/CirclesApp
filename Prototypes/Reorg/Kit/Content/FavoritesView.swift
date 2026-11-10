import SwiftUI

struct FavoritesView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16.0) {
                ForEach(FavoriteColor.allCases) { color in
                    let circles = harness.favoriteCircles.filter { harness.favorites[$0.id] == color }
                    if !circles.isEmpty {
                        VStack(alignment: .leading, spacing: 8.0) {
                            HStack(spacing: 6.0) {
                                Rectangle().fill(color.color).frame(width: 12.0, height: 12.0)
                                Text(color.name).font(.subheadline.weight(.semibold))
                                Text("\(circles.count)").font(.subheadline).foregroundStyle(.secondary)
                            }
                            CircleGrid(circles: circles)
                        }
                    }
                }
            }
            .padding(16.0)
        }
    }
}
