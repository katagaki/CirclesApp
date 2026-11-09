import SwiftUI

struct TodayFavoritesCard: View {

    @Environment(Harness.self) var harness

    var today: [MockCircle] {
        harness.favoriteCircles.filter { $0.day == harness.day }
    }

    var here: [MockCircle] {
        today.filter { $0.hall == harness.hall }
    }

    var body: some View {
        TodayCard(title: "Favorites Today", symbol: "star.fill", tint: .orange, destination: .favorites) {
            VStack(alignment: .leading, spacing: 10.0) {
                Text("\(here.count) favorites in \(harness.hall.name) today")
                    .font(.headline)
                if today.count > here.count {
                    Text("\(today.count - here.count) more in other halls")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, -8.0)
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 8.0) {
                        ForEach(here + today.filter { $0.hall != harness.hall }) { circle in
                            NavigationLink(value: circle) {
                                CircleCut(circle: circle, size: 40.0)
                                    .opacity(circle.hall == harness.hall ? 1.0 : 0.45)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
