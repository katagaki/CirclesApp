import SwiftUI

struct HubCirclesView: View {

    @Environment(Harness.self) var harness
    @Binding var filter: HubFilter

    var circles: [MockCircle] {
        let base: [MockCircle] = switch filter {
        case .all: harness.circlesForSelection
        case .favorites: harness.favoriteCircles
        case .color(let color): harness.favoriteCircles.filter { harness.favorites[$0.id] == color }
        case .visited: MockData.circles.filter { harness.visited.contains($0.id) }
        }
        guard !harness.searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(harness.searchText)
                || $0.author.localizedCaseInsensitiveContains(harness.searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12.0) {
                HubFilterChips(selection: $filter)
                if circles.isEmpty {
                    ContentUnavailableView("No Circles", systemImage: "square.grid.2x2",
                                           description: Text("Nothing matches this filter yet."))
                } else {
                    CircleGrid(circles: circles)
                        .padding(.horizontal, 16.0)
                }
            }
            .padding(.vertical, 8.0)
        }
    }
}
