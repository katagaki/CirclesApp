import SwiftUI

struct LibraryRowAccessory: View {

    @Environment(Harness.self) var harness
    let item: LibraryItem

    var body: some View {
        switch item {
        case .allCircles:
            count(harness.circlesForSelection.count)
        case .genres:
            count(MockData.genres.count)
        case .search:
            EmptyView()
        case .favorites:
            count(harness.favoriteCircles.count)
        case .favoriteColor(let color):
            count(harness.favorites.values.filter { $0 == color }.count)
        case .buys:
            if harness.buysRemaining > 0 {
                LibraryBadge(text: "\(harness.buysRemaining) left", tint: .pink)
            }
        case .sharedBuys:
            if harness.isSharedBuysActive {
                MemberStack(size: 22.0)
            } else {
                Text("Start").font(.subheadline).foregroundStyle(.secondary)
            }
        case .route:
            if harness.isNavigating {
                LibraryBadge(text: "Live · \(harness.routeStep + 1)/\(harness.routeStops.count)", tint: .blue)
            } else {
                count(harness.routeStops.count)
            }
        case .visited:
            count(harness.visited.count)
        case .myComiket:
            if harness.isGuest {
                LibraryBadge(text: "Guest", tint: .gray)
            } else {
                ProfileAvatar(size: 24.0)
            }
        case .eventData:
            if harness.isOffline {
                LibraryBadge(text: "Offline", tint: .orange)
            } else {
                Image(systemName: "checkmark.icloud").foregroundStyle(.secondary)
            }
        case .settings:
            EmptyView()
        }
    }

    func count(_ value: Int) -> some View {
        Text("\(value)")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
    }
}
