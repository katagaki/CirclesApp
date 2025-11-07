//
//  Map.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI
import TipKit

struct Map: View {

    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

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
    @State var canvasSize: CGSize = .zero

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool

    @Namespace var namespace

    var spaceSize: Int {
        useHighResolutionMaps ? 40 : 20
    }

    var mapBottomPadding: CGFloat {
        switch unifier.selectedDetent {
        case .height(120):
            return 120.0
        case .height(150):
            return 150.0
        case .height(360):
            return 360.0
        default:
            return 0
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                GeometryReader { geometry in
                    ScrollViewReader { reader in
                        ScrollView([.horizontal, .vertical]) {
                            ZStack(alignment: .topLeading) {
                                // Layout layer
                                MapLayoutLayer(
                                    image: mapImage,
                                    mappings: $layoutWebCatalogIDMappings,
                                    spaceSize: spaceSize,
                                    width: $mapImageWidth,
                                    height: $mapImageHeight,
                                    zoomDivisor: $zoomDivisor,
                                    popoverLayoutMapping: $popoverLayoutMapping,
                                    popoverWebCatalogIDSet: $popoverWebCatalogIDSet,
                                    popoverSourceRect: $popoverSourceRect,
                                    namespace: namespace
                                )
                                // Favorites layer
                                MapFavoritesLayer(
                                    mappings: $layoutFavoriteWebCatalogIDMappings,
                                    spaceSize: spaceSize,
                                    width: $mapImageWidth,
                                    height: $mapImageHeight,
                                    zoomDivisor: $zoomDivisor
                                )
                                // Genre layer
                                if showGenreOverlay, let genreImage {
                                    MapLayer(
                                        image: genreImage,
                                        width: $mapImageWidth,
                                        height: $mapImageHeight,
                                        zoomDivisor: $zoomDivisor
                                    )
                                }
                                // Popover layer
                                MapPopoverLayer(
                                    sourceRect: $popoverSourceRect,
                                    selection: $popoverWebCatalogIDSet,
                                    canvasSize: $canvasSize
                                ) { idSet, isDismissing in
                                    MapPopoverDetail(webCatalogIDSet: idSet)
                                        .id("\(isDismissing ? "!" : "")\(idSet.id)")
                                }
                            }
                        }
                        .contentMargins(.bottom, mapBottomPadding + 12.0, for: .scrollContent)
                        .contentMargins(.trailing, 120.0, for: .scrollContent)
                        .scrollIndicators(.hidden)
                        .overlay {
                            if isLoadingLayouts {
                                ZStack(alignment: .center) {
                                    if #available(iOS 26.0, *) {
                                        ProgressView("Map.LoadingLayouts")
                                            .padding()
                                            .glassEffect(.regular, in: .rect(cornerRadius: 20.0))
                                    } else {
                                        ProgressView("Map.LoadingLayouts")
                                            .padding()
                                            .background(Material.regular)
                                            .clipShape(.rect(cornerRadius: 8.0))
                                    }
                                    Color.clear
                                }
                            }
                        }
                        .overlay {
                            ZStack(alignment: .topTrailing) {
                                Color.clear
                                MapControlStack(
                                    showGenreOverlay: $showGenreOverlay,
                                    zoomDivisor: $zoomDivisor
                                )
                                .offset(x: -12.0, y: 12.0)
                            }
                        }
                        .onChange(of: popoverWebCatalogIDSet) {
                            if let popoverWebCatalogIDSet {
                                reader.scrollTo(popoverWebCatalogIDSet.id, anchor: .center)
                            }
                        }
                    }
                    .onChange(of: geometry.size) { _, newValue in
                        canvasSize = newValue
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
        .onChange(of: database.commonImages) {
            reloadAll()
        }
        .onChange(of: selections.idMap) {
            reloadAll()
        }
        .onChange(of: useHighResolutionMaps) {
            reloadAll()
        }
        .onChange(of: favorites.items) {
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
        .onChange(of: zoomDivisor) {
            popoverSourceRect = .null
            popoverLayoutMapping = nil
            popoverWebCatalogIDSet = nil
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
            // 5. Change keys to space sub number to force MapFavoriteLayerBlock to sort correctly
            // TODO
        }
        return layoutFavoriteWebCatalogIDMappings
    }
}
