import SwiftUI
import AXiS

struct FavoritesCircleCollection: View {

    @Environment(Favorites.self) var favorites
    @EnvironmentObject var filters: FavoritesFilters

    var groups: [String: [ComiketCircle]]
    var displayMode: CircleDisplayMode
    var listDisplayMode: ListDisplayMode
    var gridDisplayMode: GridDisplayMode
    var namespace: Namespace.ID
    var onSelect: (ComiketCircle) -> Void
    var onDoubleTap: ((ComiketCircle) -> Void)?

    var filteredGroups: [String: [ComiketCircle]] {
        let filteredColors = filters.colors
        let filteredHalls = filters.halls
        if filteredColors.isEmpty && filteredHalls.isEmpty {
            return groups
        }

        let mapIDsByBlockID = filters.mapIDsByBlockID
        var results: [String: [ComiketCircle]] = [:]
        for (colorKey, circles) in groups {
            if !filteredColors.isEmpty && !filteredColors.contains(Int(colorKey) ?? -1) {
                continue
            }
            if filteredHalls.isEmpty {
                results[colorKey] = circles
            } else {
                results[colorKey] = circles.filter({
                    if let mapID = mapIDsByBlockID[$0.blockID] {
                        return filteredHalls.contains(mapID)
                    }
                    return false
                })
            }
        }
        return results
    }

    var body: some View {
        let groups = filteredGroups
        Group {
            if favorites.isGroupedByColor {
                switch displayMode {
                case .grid:
                    ColorGroupedCircleGrid(
                        displayMode: gridDisplayMode,
                        groups: groups,
                        showsOverlayWhenEmpty: false,
                        namespace: namespace,
                        onSelect: onSelect,
                        onDoubleTap: onDoubleTap
                    )
                case .list:
                    ColorGroupedCircleList(
                        groups: groups,
                        showsOverlayWhenEmpty: false,
                        displayMode: listDisplayMode,
                        namespace: namespace,
                        onSelect: onSelect,
                        onDoubleTap: onDoubleTap
                    )
                }
            } else {
                let circles = groups.values.flatMap({ $0 }).sorted(by: { $0.id < $1.id })
                switch displayMode {
                case .grid:
                    CircleGrid(
                        displayMode: gridDisplayMode,
                        circles: circles,
                        showsOverlayWhenEmpty: false,
                        namespace: namespace,
                        onSelect: onSelect,
                        onDoubleTap: onDoubleTap
                    )
                case .list:
                    CircleList(
                        circles: circles,
                        showsOverlayWhenEmpty: false,
                        displayMode: listDisplayMode,
                        namespace: namespace,
                        onSelect: onSelect,
                        onDoubleTap: onDoubleTap
                    )
                }
            }
        }
        .overlay {
            if groups.allSatisfy({ $0.value.isEmpty }) {
                ContentUnavailableView(
                    "Favorites.NoFavorites",
                    systemImage: "star.leadinghalf.filled",
                    description: Text("Favorites.NoFavorites.Description")
                )
            }
        }
    }
}
