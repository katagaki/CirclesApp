import CoreLocation
import RelevanceKit
import SwiftUI
import WidgetKit

struct NextStopProvider: TimelineProvider {

    func placeholder(in context: Context) -> NextStopEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextStopEntry) -> Void) {
        Task { @MainActor in
            completion(Self.currentEntry() ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextStopEntry>) -> Void) {
        Task { @MainActor in
            let entry = Self.currentEntry() ?? .placeholder
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900.0))))
        }
    }

    func relevance() async -> WidgetRelevance<Void> {
        var attributes: [WidgetRelevanceAttribute<Void>] = []

        for interval in await Self.eventDayIntervals() {
            attributes.append(
                WidgetRelevanceAttribute(context: .date(from: interval.start, to: interval.end))
            )
        }

        let bigSight = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 35.6297, longitude: 139.7952),
            radius: 900.0,
            identifier: "TokyoBigSight"
        )
        attributes.append(WidgetRelevanceAttribute(context: .location(bigSight)))

        return WidgetRelevance(attributes)
    }

    @MainActor
    private static func currentEntry() -> NextStopEntry? {
        let store = CatalogStore()
        store.load()
        guard let stop = store.nextStop(on: SharedState.day) else { return nil }
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

    @MainActor
    private static func eventDayIntervals() -> [DateInterval] {
        let store = CatalogStore()
        store.load()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        return store.days.compactMap { day in
            var components = DateComponents()
            components.year = day.year
            components.month = day.month
            components.day = day.day
            components.hour = 9
            guard let start = calendar.date(from: components) else { return nil }
            return DateInterval(start: start, duration: 60.0 * 60.0 * 8.0)
        }
    }
}

struct NextStopWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextStopWidget", provider: NextStopProvider()) { entry in
            NextStopEntryView(entry: entry)
                .containerBackground(entry.color.opacity(0.25).gradient, for: .widget)
        }
        .configurationDisplayName("Next Stop")
        .description("The next circle on your route.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct NextStopEntryView: View {

    @Environment(\.widgetFamily) private var family

    let entry: NextStopEntry

    var body: some View {
        NextStopView(entry: entry, family: family)
    }
}
