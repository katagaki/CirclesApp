import SwiftUI
import WidgetKit

struct WidgetGalleryView: View {

    @Environment(CatalogStore.self) private var store

    private var entry: NextStopEntry {
        guard let stop = store.nextStop(on: SharedState.day) else { return .placeholder }
        return NextStopEntry(
            date: .now,
            spaceLabel: stop.favorite.spaceLabel,
            hallName: store.map(id: stop.favorite.mapID)?.name ?? "",
            circleName: stop.favorite.circle.name,
            color: stop.favorite.color.color,
            position: stop.position,
            total: stop.total,
            buyCount: store.buysSummary(forCircle: stop.favorite.circle.id).count
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10.0) {
                sample("Rectangular", family: .accessoryRectangular, width: 162.0, height: 40.0)
                sample("Circular", family: .accessoryCircular, width: 48.0, height: 48.0)
                sample("Inline", family: .accessoryInline, width: 162.0, height: 20.0)
                sample("Corner", family: .accessoryCorner, width: 60.0, height: 60.0)

                Text(SharedState.isSharedContainerAvailable
                     ? "App group: available"
                     : "App group: UNAVAILABLE")
                    .font(.caption2)
                    .foregroundStyle(SharedState.isSharedContainerAvailable ? .green : .red)
            }
            .padding(.horizontal, 4.0)
        }
        .navigationTitle("Widgets")
    }

    private func sample(
        _ title: String,
        family: WidgetFamily,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 3.0) {
            Text(title)
                .font(.system(size: 11.0, weight: .semibold))
                .foregroundStyle(.secondary)
            NextStopView(entry: entry, family: family)
                .frame(width: width, height: height)
                .padding(4.0)
                .background(entry.color.opacity(0.25), in: RoundedRectangle(cornerRadius: 8.0))
        }
    }
}
