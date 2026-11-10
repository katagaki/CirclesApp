import SwiftUI

struct LauncherSearchResults: View {

    @Environment(Harness.self) var harness

    var circles: [MockCircle] {
        MockData.circles.filter {
            $0.name.localizedCaseInsensitiveContains(harness.searchText)
                || $0.author.localizedCaseInsensitiveContains(harness.searchText)
                || $0.genre.localizedCaseInsensitiveContains(harness.searchText)
                || $0.spaceName.localizedCaseInsensitiveContains(harness.searchText)
        }
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12.0) {
            Text("\(circles.count) circles")
                .font(.headline)
                .foregroundStyle(.secondary)
            ForEach(circles) { circle in
                NavigationLink(value: circle) {
                    CircleRow(circle: circle)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
