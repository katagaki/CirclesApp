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
    @State var genreImage: UIImage?

    @State var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
    @State var isInitialLoadCompleted: Bool = false

    @State var popoverData: PopoverData?

    @AppStorage(wrappedValue: 3, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool

    var spaceSize: Int {
        useHighResolutionMaps ? 40 : 20
    }

    var mapInvalidationID: String {
        "M\(selections.fullMapID)_R\(useHighResolutionMaps ? "H" : "L")_D\(database.commonImages.count)"
    }

    var popoverInvalidationID: String {
        "Z\(zoomDivisor)_R\(useHighResolutionMaps ? 1 : 0)"
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                ScrollViewReader { reader in
                    ScrollView([.horizontal, .vertical]) {
                        ZStack(alignment: .topLeading) {
                            // Map image layer
                            MapLayer(
                                canvasSize: $canvasSize,
                                image: mapImage
                            )

                            // Favorites layer
                            MapFavoritesLayer(
                                canvasSize: $canvasSize,
                                mappings: $layoutWebCatalogIDMappings,
                                spaceSize: spaceSize
                            )

                            // Genre layer
                            if showGenreOverlay, let genreImage {
                                MapLayer(
                                    canvasSize: $canvasSize,
                                    image: genreImage
                                )
                            }

                            // Map layouts layer
                            MapLayoutLayer(
                                canvasSize: $canvasSize,
                                mappings: $layoutWebCatalogIDMappings,
                                spaceSize: spaceSize,
                                popoverData: $popoverData
                            )

                            // Popover layer
                            MapPopoverLayer(
                                canvasSize: $canvasSize,
                                selection: $popoverData,
                            ) { selection in
                                MapPopoverDetail(selection: selection)
                            }
                        }
                    }
                    .contentMargins(.bottom, unifier.safeAreaHeight + 12.0, for: .scrollContent)
                    .scrollIndicators(.hidden)
                    .onChange(of: popoverData) { _, newValue in
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
        .onChange(of: mapImage) { _, newImage in
            if let newImage {
                updateCanvasSize(newImage)
            }
        }
        .onChange(of: mapInvalidationID) {
            reloadAll()
        }
        .onChange(of: popoverInvalidationID) {
            popoverData = nil
            if let mapImage {
                updateCanvasSize(mapImage)
            }
        }
    }
}
