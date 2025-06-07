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

    @Binding var date: ComiketDate?
    @Binding var map: ComiketMap?

    @State var mapImage: UIImage?
    @State var mapImageWidth: Int = 0
    @State var mapImageHeight: Int = 0
    @State var genreImage: UIImage?

    @State var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
    @State var isLoadingLayouts: Bool = false

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
                        Image(uiImage: mapImage)
                            .resizable()
                            .frame(
                                width: CGFloat(mapImageWidth / zoomDivisor),
                                height: CGFloat(mapImageHeight / zoomDivisor)
                            )
                            .padding(.trailing, 72.0)
                            .animation(.smooth.speed(2.0), value: zoomDivisor)
                            .colorInvert(adaptive: true)
                            .onTapGesture { location in
                                if popoverWebCatalogIDSet == nil {
                                    openMapPopoverIn(x: Int(location.x), y: Int(location.y))
                                }
                            }
                            .popover(
                                item: $popoverWebCatalogIDSet,
                                attachmentAnchor: .rect(.rect(popoverSourceRect))
                            ) { _ in
                                InteractiveMapDetailPopover(
                                    webCatalogIDSet: $popoverWebCatalogIDSet,
                                    anchorRect: $popoverSourceRect
                                )
                            }
                            .overlay {
                                if popoverWebCatalogIDSet != nil {
                                    Rectangle()
                                        .foregroundStyle(Color.accent.opacity(0.3))
                                        .frame(
                                            width: popoverSourceRect.width,
                                            height: popoverSourceRect.height
                                        )
                                        .position(x: popoverSourceRect.midX, y: popoverSourceRect.midY)
                                        .transition(.opacity.animation(.smooth.speed(2.0)))
                                }
                            }
                        // Genre Layer
                        if showGenreOverlayState, let genreImage {
                            Image(uiImage: genreImage)
                                .resizable()
                                .frame(
                                    width: CGFloat(mapImageWidth / zoomDivisor),
                                    height: CGFloat(mapImageHeight / zoomDivisor)
                                )
                                .animation(.smooth.speed(2.0), value: zoomDivisor)
                                .allowsHitTesting(false)
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
                        SquareButtonStack {
                            VStack(alignment: .center, spacing: 0.0) {
                                SquareButton {
                                    withAnimation(.smooth.speed(2.0)) {
                                        showGenreOverlayState.toggle()
                                    }
                                } label: {
                                    Image(systemName: showGenreOverlayState ?
                                          "theatermask.and.paintbrush.fill" :
                                            "theatermask.and.paintbrush")
                                    .font(.title2)
                                }
                                .popoverTip(GenreOverlayTip())
                            }
                            VStack(alignment: .center, spacing: 0.0) {
                                SquareButton {
                                    zoomDivisor -= 1
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title)
                                }
                                .disabled(zoomDivisor <= 1)
                                Divider()
                                SquareButton {
                                    zoomDivisor += 1
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.title)
                                }
                                .disabled(zoomDivisor >= 4)
                            }
                        }
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
            reloadAll()
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
            reloadMapImage()
            reloadMapLayouts()
        }
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
        if let map {
            let mapID = map.id
            Task.detached {
                let actor = DataFetcher(modelContainer: sharedModelContainer)
                let layoutIdentifiers = await actor.layouts(inMap: mapID)
                await MainActor.run {
                    let mapLayouts = database.layouts(layoutIdentifiers)
                    if mapLayouts.count > 0 {
                        reloadWebCatalogIDs(mapLayouts)
                    } else {
                        layoutWebCatalogIDMappings.removeAll()
                    }
                }
            }
        }
    }

    func reloadWebCatalogIDs(_ layouts: [ComiketLayout]) {
        if let selectedDate = date?.id {
            let layoutCatalogMappings = layouts.map {
                LayoutCatalogMapping(
                    blockID: $0.blockID,
                    spaceNumber: $0.spaceNumber,
                    positionX: useHighResolutionMaps ? $0.hdPosition.x : $0.position.x,
                    positionY: useHighResolutionMaps ? $0.hdPosition.y : $0.position.y,
                    layoutType: $0.layout
                )
            }
            withAnimation(.smooth.speed(2.0)) {
                isLoadingLayouts = true
            } completion: {
                Task.detached(priority: .high) {
                    let actor = DataFetcher(modelContainer: sharedModelContainer)
                    let layoutWebCatalogIDMappings = await actor.circleWebCatalogIDs(
                        forMappings: layoutCatalogMappings, on: selectedDate
                    )
                    await MainActor.run {
                        withAnimation(.smooth.speed(2.0)) {
                            self.layoutWebCatalogIDMappings = layoutWebCatalogIDMappings
                            self.isLoadingLayouts = false
                        }
                    }
                }
            }
        }
    }

    // swiftlint:disable identifier_name
    func openMapPopoverIn(x: Int, y: Int) {
        for (layout, webCatalogIDs) in layoutWebCatalogIDMappings {
            let xMin: Int = layout.positionX / zoomDivisor
            let xMax: Int = (layout.positionX + spaceSize) / zoomDivisor
            let yMin: Int = layout.positionY / zoomDivisor
            let yMax: Int = (layout.positionY + spaceSize) / zoomDivisor
            if x >= xMin && x < xMax && y >= yMin && y < yMax {
                let spaceSize = spaceSize / zoomDivisor
                popoverSourceRect = CGRect(x: xMin, y: yMin, width: spaceSize, height: spaceSize)
                popoverWebCatalogIDSet = WebCatalogIDSet(ids: webCatalogIDs)
                break
            }
        }
    }
    // swiftlint:enable identifier_name
}
