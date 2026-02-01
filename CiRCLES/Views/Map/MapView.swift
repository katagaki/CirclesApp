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

    @AppStorage(wrappedValue: 1.0, "Map.ZoomScale") var zoomScale: Double
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
        "R\(useHighResolutionMaps ? 1 : 0)"
    }

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                MapScrollView(zoomScale: Binding(
                    get: { CGFloat(zoomScale) },
                    set: { zoomScale = Double($0) }
                )) {
                    ZStack(alignment: .topLeading) {
                        MapLayer(image: mapImage)
                        MapFavoritesLayer(spaceSize: spaceSize)
                        MapVisitedLayer(spaceSize: spaceSize)
                        if showGenreOverlay, let genreImage {
                            MapLayer(image: genreImage)
                        }
                        MapLayoutLayer(spaceSize: spaceSize)
                        MapHighlightLayer()
                        MapPopoverLayer(zoomScale: zoomScale) { selection in
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
                        spaceSize: spaceSize
                    )
                    if !shouldHighlight {
                        if let circle = newValue {
                            let actor = DataFetcher(database: database.getTextDatabase())
                            if let mapID = await actor.mapID(forBlock: circle.blockID) {
                                let maps = database.maps()
                                let dates = database.dates()
                                if let newMap = maps.first(where: { $0.id == mapID }),
                                   let newDate = dates.first(where: { $0.id == circle.day }) {
                                    if selections.map?.id != newMap.id || selections.date?.id != newDate.id {
                                        selections.map = newMap
                                        selections.date = newDate
                                        return
                                    }
                                }
                            }
                        }
                        mapper.highlightTarget = nil
                    }
                }
            }
        }
        .onChange(of: mapper.layouts) {
            if mapper.highlightTarget != nil {
                Task {
                    _ = await mapper.highlightCircle(
                        spaceSize: spaceSize
                    )
                }
            }
        }
    }
}
