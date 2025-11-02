//
//  InteractiveMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI
import TipKit

struct InteractiveMap: View {

    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites
    @Environment(UserSelections.self) var selections

    @State var mapImage: UIImage?
    @State var mapImageWidth: Int = 0
    @State var mapImageHeight: Int = 0
    @State var genreImage: UIImage?

    @State var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
    @State var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
    @State var isInitialLoadCompleted: Bool = false
    @State var isLoadingLayouts: Bool = false

    @State var popoverLayoutMapping: LayoutCatalogMapping?
    @State var popoverWebCatalogIDSet: WebCatalogIDSet?
    @State var popoverSourceRect: CGRect = .null

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int

    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool

    var spaceSize: Int {
        useHighResolutionMaps ? 40 : 20
    }

    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .topLeading) {
                        // Map Layer
                        HallMap(
                            image: mapImage,
                            mappings: $layoutWebCatalogIDMappings,
                            spaceSize: spaceSize,
                            width: $mapImageWidth,
                            height: $mapImageHeight,
                            zoomDivisor: $zoomDivisor,
                            namespace: namespace
                        )
                        // Favorites Layer
                        HallFavoritesOverlay(
                            mappings: $layoutFavoriteWebCatalogIDMappings,
                            spaceSize: spaceSize,
                            width: $mapImageWidth,
                            height: $mapImageHeight,
                            zoomDivisor: $zoomDivisor
                        )
                        // Genre Layer
                        if showGenreOverlay, let genreImage {
                            HallOverlay(
                                image: genreImage,
                                width: $mapImageWidth,
                                height: $mapImageHeight,
                                zoomDivisor: $zoomDivisor
                            )
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .overlay {
                    if isLoadingLayouts {
                        ZStack(alignment: .center) {
                            ProgressView("Map.LoadingLayouts")
                                .padding()
                                .background(Material.regular)
                                .clipShape(.rect(cornerRadius: 8.0))
                            Color.clear
                        }
                    }
                }
                .overlay {
                    ZStack(alignment: .topTrailing) {
                        MapControlStack(
                            showGenreOverlay: $showGenreOverlay,
                            useDarkModeMaps: $useDarkModeMaps,
                            zoomDivisor: $zoomDivisor
                        )
                        .offset(x: -12.0, y: 12.0)
                        Color.clear
                    }
                }
            } else {
                ContentUnavailableView(
                    "Map.NoMapSelected",
                    systemImage: "doc.questionmark",
                    description: Text("Map.NoMapSelected.Description")
                )
            }
        }
        .onAppear {
            if !isInitialLoadCompleted {
                isInitialLoadCompleted = true
                reloadAll()
            }
        }
        .onChange(of: database.commonImages) { _, _ in
            reloadAll()
        }
        .onChange(of: selections.idMap) { _, _ in
            reloadAll()
        }
        .onChange(of: useHighResolutionMaps) { _, _ in
            reloadMapImage()
        }
        .onChange(of: favorites.items) { _, _ in
            Task.detached(priority: .high) {
                await reloadFavorites()
            }
        }
        .onChange(of: mapImage) { _, newValue in
            if let newValue {
                mapImageWidth = Int(newValue.size.width)
                mapImageHeight = Int(newValue.size.height)
            }
        }
    }

    func reloadAll() {
        withAnimation(.smooth.speed(2.0)) {
            isLoadingLayouts = true
            removeAllMappings()
            reloadMapImage()
        } completion: {
            if let map = selections.map {
                let mapID = map.id
                let selectedDate = selections.date?.id
                let useHighResolutionMaps = useHighResolutionMaps
                Task.detached(priority: .high) {
                    await reloadMapLayouts(
                        mapID: mapID,
                        selectedDate: selectedDate,
                        useHighResolutionMaps: useHighResolutionMaps
                    )
                    await reloadFavorites()
                }
            }
        }
    }

    func removeAllMappings() {
        layoutWebCatalogIDMappings.removeAll()
        layoutFavoriteWebCatalogIDMappings.removeAll()
    }

    func reloadMapImage() {
        if let date = selections.date,
           let map = selections.map,
           let selectedHall = ComiketHall(rawValue: map.filename) {
            mapImage = database.mapImage(
                for: selectedHall,
                on: date.id,
                usingHighDefinition: useHighResolutionMaps
            )
            genreImage = database.genreImage(
                for: selectedHall,
                on: date.id,
                usingHighDefinition: useHighResolutionMaps
            )
        } else {
            mapImage = nil
            genreImage = nil
        }
    }

    func reloadMapLayouts(mapID: Int, selectedDate: Int?, useHighResolutionMaps: Bool) async {
        var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
        if let selectedDate {
            // Fetch map layouts
            let actor = DataFetcher(modelContainer: sharedModelContainer)
            let layoutCatalogMappings = await actor.layoutMappings(
                inMap: mapID,
                useHighResolutionMaps: useHighResolutionMaps
            )
            // Create Layout Mapping <> Web Catalog ID mapping data
            if layoutCatalogMappings.count > 0 {
                layoutWebCatalogIDMappings = await actor.layoutCatalogMappingToWebCatalogIDs(
                    forMappings: layoutCatalogMappings, on: selectedDate
                )
            }
        }

        // Send results back to the view
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.layoutWebCatalogIDMappings = layoutWebCatalogIDMappings
                isLoadingLayouts = false
            }
        }
    }

    func reloadFavorites() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        // Create favorites mapping for Web Catalog IDs
        let layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(
            layoutWebCatalogIDMappings
        )
        // List out all Web Catalog IDs
        let webCatalogIDs: [Int] = Array(Set(
            layoutFavoriteWebCatalogIDMappings.values
                .reduce(into: [] as [Int]) { result, webCatalogIDs in
                    result.append(contentsOf: webCatalogIDs.keys)
                }
        ))
        // Map all Web Catalog IDs to space number suffixes
        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(
            forWebCatalogIDs: webCatalogIDs
        )
        // Replace Web Catalog IDs with space number suffixes
        let layoutFavoriteWebCatalogIDSorted = layoutFavoriteWebCatalogIDMappings
            .reduce(into: [LayoutCatalogMapping: [Int: WebCatalogColor?]]()) { result, keyValue in
                let mapping = keyValue.key
                let colorMapping = keyValue.value
                result[mapping] = colorMapping
                    .reduce(into: [Int: WebCatalogColor?]()) { result, keyValue in
                        let webCatalogID = keyValue.key
                        let color = keyValue.value
                        result[spaceNumberSuffixes[webCatalogID] ?? webCatalogID] = color
                    }
        }

        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.layoutFavoriteWebCatalogIDMappings = layoutFavoriteWebCatalogIDSorted
            }
        }
    }

    func mapFavoriteMappings(
        _ layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]]
    ) -> [LayoutCatalogMapping: [Int: WebCatalogColor?]] {
        var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
        if let webCatalogIDMappedItems = favorites.wcIDMappedItems {
            for (webCatalogID, favoriteItem) in webCatalogIDMappedItems {
                // 1. Find the layout catalog mapping that matches the Web Catalog ID
                let matchingLayoutMaps: [LayoutCatalogMapping: [Int]] = layoutWebCatalogIDMappings
                    .filter { $1.contains(webCatalogID) }

                // 2. Ensure that only one layout is selected
                if let (matchedLayoutMap, _) = matchingLayoutMaps.first {
                    // 3. Set up the sub-dictionary for the favorites mapping
                    if layoutFavoriteWebCatalogIDMappings[matchedLayoutMap] == nil {
                        let webCatalogIDs = layoutWebCatalogIDMappings[matchedLayoutMap] ?? []
                        layoutFavoriteWebCatalogIDMappings[matchedLayoutMap] = webCatalogIDs
                            .reduce(into: [:]) { partialResult, webCatalogID in
                                let nilColor: WebCatalogColor? = nil
                                partialResult[webCatalogID] = nilColor
                            }
                    }

                    // 4. Set the color for the Web Catalog ID in the favorites mapping
                    layoutFavoriteWebCatalogIDMappings[matchedLayoutMap]?[webCatalogID] = favoriteItem.favorite.color
                }
            }
            // 5. Change keys to space sub number to force MapFavoriteBlock to sort correctly
            // TODO
        }
        return layoutFavoriteWebCatalogIDMappings
    }
}
