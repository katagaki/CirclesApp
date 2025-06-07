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

    @Binding var date: ComiketDate?
    @Binding var map: ComiketMap?

    @State var mapImage: UIImage?
    @State var mapImageWidth: Int = 0
    @State var mapImageHeight: Int = 0
    @State var genreImage: UIImage?

    @State var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
    @State var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
    @State var isLoadingLayouts: Bool = false

    @State var popoverLayoutMapping: LayoutCatalogMapping?
    @State var popoverWebCatalogIDSet: WebCatalogIDSet?
    @State var popoverSourceRect: CGRect = .null

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @State var showGenreOverlayState: Bool = false

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int

    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool

    var dateMap: [Int?] {[
        date?.id,
        map?.id
    ]}

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
                        if showGenreOverlayState, let genreImage {
                            HallOverlay(
                                image: genreImage,
                                width: $mapImageWidth,
                                height: $mapImageHeight,
                                zoomDivisor: $zoomDivisor
                            )
                            .transition(.opacity.animation(.smooth.speed(2.0)))
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
                    ZStack(alignment: .bottomTrailing) {
                        MapControlStack(
                            showGenreOverlay: $showGenreOverlayState,
                            zoomDivisor: $zoomDivisor
                        )
                        .offset(x: -12.0, y: -12.0)
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
            showGenreOverlayState = showGenreOverlay
        }
        .onChange(of: database.commonImages) { _, _ in
            reloadAll()
        }
        .onChange(of: dateMap) { _, _ in
            reloadAll()
        }
        .onChange(of: useHighResolutionMaps) { _, _ in
            reloadMapImage()
        }
        .onChange(of: favorites.items) { _, _ in
            self.layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(layoutWebCatalogIDMappings)
        }
        .onChange(of: mapImage) { _, newValue in
            if let newValue {
                mapImageWidth = Int(newValue.size.width)
                mapImageHeight = Int(newValue.size.height)
            }
        }
        .onChange(of: showGenreOverlayState) { _, _ in
            showGenreOverlay = showGenreOverlayState
        }
    }

    func reloadAll() {
        withAnimation(.snappy.speed(2.0)) {
            removeAllMappings()
            reloadMapImage()
            reloadMapLayouts()
        }
    }

    func removeAllMappings() {
        layoutWebCatalogIDMappings.removeAll()
        layoutFavoriteWebCatalogIDMappings.removeAll()
    }

    func reloadMapImage() {
        if let date, let map, let selectedHall = ComiketHall(rawValue: map.filename) {
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

    func reloadMapLayouts() {
        withAnimation(.smooth.speed(2.0)) {
            isLoadingLayouts = true
        } completion: {
            if let map {
                let mapID = map.id
                let selectedDate = date?.id
                let useHighResolutionMaps = useHighResolutionMaps
                if let selectedDate {
                    Task.detached {
                        // Fetch map layouts
                        let actor = DataFetcher(modelContainer: sharedModelContainer)
                        let layoutCatalogMappings = await actor.layoutMappings(
                            inMap: mapID,
                            useHighResolutionMaps: useHighResolutionMaps
                        )

                        if layoutCatalogMappings.count > 0 {
                            // Mappings returned, create Layout Mapping <> Web Catalog ID mapping data
                            let actor = DataFetcher(modelContainer: sharedModelContainer)
                            let layoutWebCatalogIDMappings = await actor.circleWebCatalogIDs(
                                forMappings: layoutCatalogMappings, on: selectedDate
                            )

                            await MainActor.run {
                                withAnimation(.smooth.speed(2.0)) {
                                    self.layoutWebCatalogIDMappings = layoutWebCatalogIDMappings
                                    self.layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(
                                        layoutWebCatalogIDMappings
                                    )
                                    self.isLoadingLayouts = false
                                }
                            }

                        } else {
                            // No mappings, clear all existing mapping
                            await MainActor.run {
                                withAnimation(.smooth.speed(2.0)) {
                                    layoutWebCatalogIDMappings.removeAll()
                                    self.isLoadingLayouts = false
                                }
                            }
                        }
                    }
                }
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
        }
        return layoutFavoriteWebCatalogIDMappings
    }
}
