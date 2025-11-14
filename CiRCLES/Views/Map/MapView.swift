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
    @State var popoverPosition: CGPoint?
    @State var scrollToPosition: CGPoint?

    @AppStorage(wrappedValue: 3, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: 0, "Map.ScrollType") var scrollType: Int

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
                MapScrollView(
                    scrollToPosition: $scrollToPosition
                ) {
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
                            popoverPosition: $popoverPosition,
                        ) { selection in
                            MapPopoverDetail(selection: selection)
                        }
                    }
                }
                .onChange(of: popoverPosition) { _, newValue in
                    if MapAutoScrollType(rawValue: scrollType) == .popover {
                        scrollToPosition = newValue
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
            popoverData = nil
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
