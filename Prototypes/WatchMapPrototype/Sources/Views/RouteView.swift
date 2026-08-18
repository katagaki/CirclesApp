import SwiftUI

struct RouteView: View {

    @Environment(CatalogStore.self) private var store

    @AppStorage(wrappedValue: 1, "Prototype.Day") private var selectedDay: Int

    @State private var selection: Int = 0

    private var route: [Favorite] {
        store.favorites(on: selectedDay)
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(route.enumerated()), id: \.element.id) { index, favorite in
                RouteCard(favorite: favorite, position: index + 1, total: route.count)
                    .tag(favorite.id)
            }
            RouteMenuPage(selectedDay: $selectedDay)
                .tag(-1)
        }
        .tabViewStyle(.verticalPage)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if UserDefaults.standard.string(forKey: "Prototype.RouteSelection") == "menu" {
                selection = -1
            } else if selection == 0,
                      let first = route.first(where: { !store.isVisited($0.id) }) ?? route.first {
                selection = first.id
            }
        }
        .onChange(of: selectedDay) {
            SharedState.day = selectedDay
            selection = route.first?.id ?? -1
        }
    }
}

struct RouteCard: View {

    @Environment(CatalogStore.self) private var store
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let favorite: Favorite
    let position: Int
    let total: Int

    private var isVisited: Bool {
        store.isVisited(favorite.id)
    }

    var body: some View {
        VStack(spacing: 0.0) {
            header

            Spacer(minLength: 0.0)

            Text(favorite.spaceLabel)
                .font(.system(size: 46.0, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .strikethrough(isVisited, pattern: .solid, color: .secondary)
                .foregroundStyle(isVisited ? .secondary : favorite.color.color)

            Text(store.map(id: favorite.mapID)?.name ?? "")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)

            if !isLuminanceReduced {
                Text(favorite.circle.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)

                let summary = store.buysSummary(forCircle: favorite.circle.id)
                if summary.count > 0 {
                    Text("\(summary.count) items · ¥\(summary.total)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 1.0)
                }
            }

            Spacer(minLength: 0.0)

            if !isLuminanceReduced {
                actions
            }
        }
        .padding(.horizontal, 6.0)
        .padding(.bottom, 4.0)
        .containerBackground(
            favorite.color.color.gradient.opacity(isLuminanceReduced ? 0.0 : 0.28),
            for: .tabView
        )
    }

    private var header: some View {
        HStack {
            Text("\(position)/\(total)")
                .font(.system(size: 12.0, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            if isVisited {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12.0))
                    .foregroundStyle(.green)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 6.0) {
            NavigationLink(value: MapRoute(favorite: favorite)) {
                Image(systemName: "map.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                store.toggleVisited(favorite.id)
            } label: {
                Image(systemName: isVisited ? "arrow.uturn.backward" : "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isVisited ? .gray : .green)
        }
        .font(.footnote)
    }
}

struct RouteMenuPage: View {

    @Environment(CatalogStore.self) private var store

    @Binding var selectedDay: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 6.0) {
                Text("\(store.favorites(on: selectedDay).filter { store.isVisited($0.id) }.count)"
                     + " / \(store.favorites(on: selectedDay).count) visited")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Day", selection: $selectedDay) {
                    ForEach(store.days) { day in
                        Text(day.shortLabel).tag(day.id)
                    }
                }
                .pickerStyle(.navigationLink)

                NavigationLink {
                    FavoritesListView()
                } label: {
                    Label("All Favorites", systemImage: "star.fill")
                }

                NavigationLink {
                    BuysView()
                } label: {
                    Label("Buys", systemImage: "cart.fill")
                }

                NavigationLink {
                    MapLabView()
                } label: {
                    Label("Map Lab", systemImage: "map")
                }

                NavigationLink {
                    WidgetGalleryView()
                } label: {
                    Label("Widgets", systemImage: "rectangle.stack")
                }
            }
            .padding(.horizontal, 4.0)
        }
    }
}
