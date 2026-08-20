import SwiftUI

struct RootView: View {

    private var launchOverride: String? {
        UserDefaults.standard.string(forKey: "Prototype.Launch")
    }

    private var launchApproach: MapApproach? {
        switch launchOverride {
        case "step": return .step
        case "focus": return .focus
        case "panZoom": return .panZoom
        case "overview": return .overview
        case "directions": return .directions
        default: return nil
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let launchApproach {
                    ApproachSamplerView(approach: launchApproach)
                } else if launchOverride == "favorites" {
                    FavoritesListView()
                } else if launchOverride == "buys" {
                    BuysView()
                } else if launchOverride == "lab" {
                    MapLabView()
                } else if launchOverride == "widgets" {
                    WidgetGalleryView()
                } else {
                    RouteView()
                }
            }
            .navigationDestination(for: Favorite.self) { favorite in
                CircleDetailView(favorite: favorite)
            }
            .navigationDestination(for: MapRoute.self) { route in
                StepMapView(favorite: route.favorite)
            }
        }
    }
}

struct MapLabView: View {

    @AppStorage(wrappedValue: true, "Prototype.InvertMap") private var invertMap: Bool

    var body: some View {
        List {
            Section {
                ForEach(MapApproach.allCases) { approach in
                    NavigationLink {
                        ApproachSamplerView(approach: approach)
                    } label: {
                        VStack(alignment: .leading, spacing: 1.0) {
                            Text(approach.title)
                            Text(approach.summary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Toggle("Invert Map", isOn: $invertMap)
            } footer: {
                Text("Demo data: Comic Market 999")
                    .font(.caption2)
            }
        }
        .navigationTitle("Map Lab")
    }
}

struct ApproachSamplerView: View {

    @Environment(CatalogStore.self) private var store

    let approach: MapApproach

    @State private var index: Int = 0

    private var favorite: Favorite? {
        guard !store.favorites.isEmpty else { return nil }
        return store.favorites[min(index, store.favorites.count - 1)]
    }

    var body: some View {
        Group {
            if let favorite {
                content(for: favorite)
            } else {
                ContentUnavailableView("No favorites", systemImage: "star.slash")
            }
        }
        .navigationTitle(approach == .step ? "" : approach.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if approach != .step {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        index = (index + 1) % max(store.favorites.count, 1)
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func content(for favorite: Favorite) -> some View {
        switch approach {
        case .step: StepMapView(favorite: favorite)
        case .focus: FocusMapView(favorite: favorite)
        case .panZoom: PanZoomMapView(favorite: favorite)
        case .overview: OverviewMapView(favorite: favorite)
        case .directions: DirectionsView(favorite: favorite)
        }
    }
}
