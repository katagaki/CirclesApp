import SwiftUI

struct FavoritesListView: View {

    @Environment(CatalogStore.self) private var store

    var body: some View {
        List {
            ForEach(store.days) { day in
                Section(day.shortLabel) {
                    ForEach(store.favorites(on: day.id)) { favorite in
                        NavigationLink(value: favorite) {
                            FavoriteRow(favorite: favorite)
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

struct FavoriteRow: View {

    @Environment(CatalogStore.self) private var store

    let favorite: Favorite

    var body: some View {
        HStack(spacing: 8.0) {
            RoundedRectangle(cornerRadius: 2.0)
                .fill(favorite.color.color)
                .frame(width: 4.0)
            VStack(alignment: .leading, spacing: 1.0) {
                Text(favorite.spaceLabel)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text(favorite.circle.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                Text(store.map(id: favorite.mapID)?.name ?? "")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2.0)
    }
}
