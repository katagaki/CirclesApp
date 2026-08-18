import SwiftUI

struct CircleDetailView: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(favorite.spaceLabel)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(favorite.color.color)
                    Text(favorite.circle.name)
                        .font(.body)
                    Text(favorite.circle.penName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                NavigationLink(value: MapRoute(favorite: favorite)) {
                    Label("Show on Map", systemImage: "map.fill")
                }
            }

            let items = store.buys(forCircle: favorite.circle.id)
            if !items.isEmpty {
                Section("Buys") {
                    ForEach(items) { item in
                        BuyRow(item: item)
                    }
                }
            }

            Section {
                LabeledContent("Hall", value: store.map(id: favorite.mapID)?.name ?? "-")
                if let day = store.day(id: favorite.circle.day) {
                    LabeledContent("Day", value: "\(day.shortLabel) (\(day.dateLabel))")
                }
                LabeledContent("Color", value: favorite.color.name)
            }
        }
        .navigationTitle(favorite.spaceLabel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MapRoute: Hashable {
    let favorite: Favorite
}
