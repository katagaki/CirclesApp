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
    @Environment(Mapper.self) var mapper
    @Environment(Unifier.self) var unifier

    @State var mapImage: UIImage?
    @State var genreImage: UIImage?

    @State var isInitialLoadCompleted: Bool = false

    @AppStorage(wrappedValue: 3, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: .none, "Map.ScrollType") var scrollType: MapAutoScrollType

    var spaceSize: Int {
        useHighResolutionMaps ? 40 : 20
    }

    var mapInvalidationID: String {
        "M\(selections.fullMapID)_R\(useHighResolutionMaps ? "H" : "L")_D\(database.commonImagesLoadCount)"
    }

    var popoverInvalidationID: String {
        "Z\(zoomDivisor)_R\(useHighResolutionMaps ? 1 : 0)"
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                MapScrollView {
                    ZStack(alignment: .topLeading) {
                        MapLayer(image: mapImage)
                        MapFavoritesLayer(spaceSize: spaceSize)
                        if showGenreOverlay, let genreImage {
                            MapLayer(image: genreImage)
                        }
                        MapLayoutLayer(spaceSize: spaceSize)
                        MapHighlightLayer()
                        MapPopoverLayer { selection in
                            MapPopoverDetail(selection: selection)
                        }
                    }
                }
                .onChange(of: mapper.popoverPosition) { _, newValue in
                    if scrollType == .popover {
                        mapper.scrollToPosition = newValue
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
            mapper.popoverData = nil
            reloadAll()
        }
        .onChange(of: popoverInvalidationID) {
            mapper.popoverData = nil
            if let mapImage {
                updateCanvasSize(mapImage)
            }
        }
        .onChange(of: mapper.highlightTarget) { oldValue, newValue in
            if oldValue == nil && newValue != nil {
                Task {
                    let shouldHighlight = await mapper.highlightCircle(
                        zoomDivisor: zoomDivisor, spaceSize: spaceSize
                    )
                    if !shouldHighlight {
                        mapper.highlightTarget = nil
                        unifier.isCircleNotInMapAlertShowing = true
                    }
                }
            }
        }
    }
}
