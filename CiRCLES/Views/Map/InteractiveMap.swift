//
//  InteractiveMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI
import TipKit

struct InteractiveMap: View {

    @Environment(DatabaseManager.self) var database

    let spaceSize: Int = 40

    @Binding var date: ComiketDate?
    @Binding var map: ComiketMap?

    @State var mapImage: UIImage?
    @State var genreImage: UIImage?

    @State var layouts: [ComiketLayout] = []
    @State var layoutWebCatalogIDMappings: [[Int]: [Int]] = [:]
    @State var isLoadingLayouts: Bool = false

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int

    var dateMap: [Int?] {[
        date?.id,
        map?.id
    ]}

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: mapImage)
                        .resizable()
                        .frame(
                            width: CGFloat(Int(mapImage.size.width) / zoomDivisor),
                            height: CGFloat(Int(mapImage.size.height) / zoomDivisor)
                        )
                        .padding(.trailing, 72.0)
                        .animation(.smooth.speed(2.0), value: zoomDivisor)
                        .colorInvert(adaptive: true)
                        .overlay {
                            if showGenreOverlay, let genreImage {
                                Image(uiImage: genreImage)
                                    .resizable()
                                    .frame(
                                        width: CGFloat(Int(mapImage.size.width) / zoomDivisor),
                                        height: CGFloat(Int(mapImage.size.height) / zoomDivisor)
                                    )
                                    .animation(.smooth.speed(2.0), value: zoomDivisor)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay {
                            if let date {
                                ZStack(alignment: .topLeading) {
                                    ForEach(Array(layoutWebCatalogIDMappings.keys), id: \.self) { layout in
//                                        Color(red: CGFloat.random(in: 0...1),
//                                              green: CGFloat.random(in: 0...1),
//                                              blue: CGFloat.random(in: 0...1))
                                        InteractiveMapButton(selectedEventDateID: date.id,
                                                             layoutBlockID: layout[0],
                                                             layoutSpaceNumber: layout[1],
                                                             webCatalogIDs: layoutWebCatalogIDMappings[layout] ?? [])
                                        .id(layout)
                                        .position(
                                            x: CGFloat((layout[2] + Int(spaceSize / 2)) / zoomDivisor),
                                            y: CGFloat((layout[3] + Int(spaceSize / 2)) / zoomDivisor)
                                        )
                                        .frame(
                                            width: CGFloat(spaceSize / zoomDivisor),
                                            height: CGFloat(spaceSize / zoomDivisor),
                                            alignment: .topLeading
                                        )
                                    }
                                    Color.clear
                                }
                            }
                        }
                }
                .scrollIndicators(.hidden)
                .overlay {
                    if isLoadingLayouts {
                        ZStack(alignment: .center) {
                            ProgressView()
                                .padding()
                                .background(Material.regular)
                                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                            Color(uiColor: .systemBackground).opacity(0.2)
                        }
                    }
                }
                .overlay {
                    ZStack(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing, spacing: 12.0) {
                            Group {
                                VStack(alignment: .center, spacing: 0.0) {
                                    Button {
                                        showGenreOverlay.toggle()
                                    } label: {
                                        Group {
                                            if showGenreOverlay {
                                                Image(systemName: "theatermask.and.paintbrush.fill")
                                            } else {
                                                Image(systemName: "theatermask.and.paintbrush")
                                            }
                                        }
                                        .font(.title2)
                                    }
                                    .frame(width: 48.0, height: 48.0, alignment: .center)
                                    .contentShape(.rect)
                                    .popoverTip(GenreOverlayTip())
                                }
                                VStack(alignment: .center, spacing: 0.0) {
                                    Button {
                                        zoomDivisor -= 1
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.title)
                                    }
                                    .frame(width: 48.0, height: 48.0, alignment: .center)
                                    .contentShape(.rect)
                                    .disabled(zoomDivisor <= 1)
                                    Divider()
                                    Button {
                                        zoomDivisor += 1
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.title)
                                    }
                                    .frame(width: 48.0, height: 48.0, alignment: .center)
                                    .contentShape(.rect)
                                    .disabled(zoomDivisor >= 3)
                                }
                            }
                            .background(Material.regular)
                            .clipShape(.rect(cornerRadius: 8.0))
                            .shadow(color: .black.opacity(0.2), radius: 4.0, y: 2.0)
                        }
                        .frame(maxWidth: 48.0)
                        .offset(x: -12.0, y: -12.0)
                        Color.clear
                    }
                }
            }
        }
        .onAppear {
            if mapImage == nil || genreImage == nil {
                reloadAll()
            }
        }
        .onChange(of: database.commonImages) { _, _ in
            reloadAll()
        }
        .onChange(of: dateMap) { _, _ in
            reloadAll()
        }
        .onChange(of: layouts) { _, newValue in
            if newValue.count > 0 {
                reloadWebCatalogIDs()
            } else {
                layoutWebCatalogIDMappings.removeAll()
            }
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
                usingHighDefinition: true
            )
            genreImage = database.genreImage(
                for: selectedHall,
                on: date.id,
                usingHighDefinition: true
            )
        }
    }

    func reloadMapLayouts() {
        withAnimation(.snappy.speed(2.0)) {
            layouts.removeAll()
        } completion: {
            if let map {
                let mapID = map.id
                Task.detached {
                    let actor = DataFetcher(modelContainer: sharedModelContainer)
                    let layoutIdentifiers = await actor.layouts(inMap: mapID)
                    await MainActor.run {
                        let mapLayouts = database.layouts(layoutIdentifiers)
                        self.layouts = mapLayouts
                    }
                }
            }
        }
    }

    func reloadWebCatalogIDs() {
        debugPrint("Reloading web catalog ID mappings")
        if let selectedDate = date?.id {
            let layoutBlockIDAndSpaceNumbers = layouts.map {
                [$0.blockID, $0.spaceNumber, $0.hdPosition.x, $0.hdPosition.y]
            }
            withAnimation(.smooth.speed(2.0)) {
                isLoadingLayouts = true
            } completion: {
                Task.detached {
                    let actor = DataFetcher(modelContainer: sharedModelContainer)
                    var layoutWebCatalogIDMappings: [[Int]: [Int]] = [:]
                    for blockIDAndSpaceNumber in layoutBlockIDAndSpaceNumbers {
                        debugPrint("Reloading web catalog ID mappings for \(blockIDAndSpaceNumber)")
                        let webCatalogIDs = await actor.circleWebCatalogIDs(
                            inBlock: blockIDAndSpaceNumber[0],
                            inSpace: blockIDAndSpaceNumber[1],
                            on: selectedDate
                        )
                        layoutWebCatalogIDMappings[blockIDAndSpaceNumber] = webCatalogIDs
                    }
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
}
