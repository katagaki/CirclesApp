import SwiftUI

struct CircleDetailView: View {

    @Environment(Harness.self) var harness
    let circle: MockCircle

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 16.0) {
                    CircleCut(circle: circle, size: 90.0)
                    VStack(alignment: .leading, spacing: 6.0) {
                        Text(circle.name).font(.title3.weight(.bold))
                        Text(circle.author).foregroundStyle(.secondary)
                        HStack {
                            SpaceBadge(circle: circle)
                            Text(circle.dayName).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(circle.genre).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }
            Section {
                HStack(spacing: 10.0) {
                    CircleDetailAction(title: harness.favorites[circle.id] == nil ? "Favorite" : "Favorited",
                                       symbol: harness.favorites[circle.id] == nil ? "star" : "star.fill",
                                       tint: harness.favorites[circle.id]?.color ?? .orange) {
                        harness.toggleFavorite(circle)
                    }
                    CircleDetailAction(title: "Add Buy", symbol: "bag.badge.plus", tint: .pink) {}
                    CircleDetailAction(title: "Visited", symbol: "checkmark.circle", tint: .green) {
                        harness.visited.insert(circle.id)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            Section("Buys at this circle") {
                ForEach(harness.buys.filter { $0.circleID == circle.id }) { item in
                    BuyRow(item: item)
                }
                if harness.buys.allSatisfy({ $0.circleID != circle.id }) {
                    Text("Nothing planned yet").foregroundStyle(.secondary)
                }
            }
            Section("Description") {
                Text("新刊とグッズを頒布予定です。よろしくお願いします！ New book and goods available on \(circle.dayName).")
                    .font(.callout)
            }
        }
        .navigationTitle(circle.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { harness.selectedCircle = circle }
    }
}
