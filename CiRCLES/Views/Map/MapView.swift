//
//  MapView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI
import TipKit

struct MapView: View {

    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    @State var canvasSize: CGSize = .zero

    @State var mapImage: UIImage?
    @State var mapImageWidth: Int = 0
    @State var mapImageHeight: Int = 0
    @State var genreImage: UIImage?

    @State var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
    @State var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
    @State var isInitialLoadCompleted: Bool = false

    @State var popoverLayoutMapping: LayoutCatalogMapping?
    @State var popoverWebCatalogIDSet: WebCatalogIDSet?
    @State var popoverSourceRect: CGRect = .null

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool

    @Namespace var namespace

    var spaceSize: Int {
        useHighResolutionMaps ? 40 : 20
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
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
                            .allowsHitTesting(false)
                            // Genre layer
                            if showGenreOverlay, let genreImage {
                                MapLayer(
                                    image: genreImage,
                                    width: $mapImageWidth,
                                    height: $mapImageHeight,
                                    zoomDivisor: $zoomDivisor
                                )
                                .allowsHitTesting(false)
                            }
                            // Popover layer
                            MapPopoverLayer(
                                canvasSize: $canvasSize,
                                sourceRect: $popoverSourceRect,
                                selection: $popoverWebCatalogIDSet,
                            ) { idSet, isDismissing in
                                MapPopoverDetail(webCatalogIDSet: idSet)
                                    .id("\(isDismissing ? "!" : "")\(idSet.id)")
                            }
                        }
                        .background {
                            GeometryReader { reader in
                                Color.clear
                                    .onChange(of: reader.size) { _, newValue in
                                        canvasSize = newValue
                                    }
                            }
                        }
                    }
                    .contentMargins(.bottom, unifier.safeAreaHeight + 12.0, for: .scrollContent)
                    .contentMargins(.trailing, 120.0, for: .scrollContent)
                    .scrollIndicators(.hidden)
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
                    .onChange(of: popoverWebCatalogIDSet) { _, newValue in
                        if let newValue {
                            reader.scrollTo("\(newValue.id)", anchor: .center)
                        }
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
        .onChange(of: selections.fullMapId) {
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
}
