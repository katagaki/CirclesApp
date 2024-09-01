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

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int

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
                            ZStack(alignment: .topLeading) {
                                ForEach(layouts, id: \.self) { layout in
                                    InteractiveMapButton(selectedEventDate: $date, layout: layout)
                                        .id(String(layout.blockID) + "|" + String(layout.spaceNumber))
                                        .position(
                                            x: CGFloat((layout.hdPosition.x + Int(spaceSize / 2)) / zoomDivisor),
                                            y: CGFloat((layout.hdPosition.y + Int(spaceSize / 2)) / zoomDivisor)
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
                .scrollIndicators(.hidden)
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
            reloadAll()
        }
        .onChange(of: database.commonImages) { _, _ in
            reloadAll()
        }
        .onChange(of: date) { _, _ in
            reloadAll()
        }
        .onChange(of: map) { _, _ in
            reloadAll()
        }
    }

    func reloadAll() {
        withAnimation(.snappy.speed(2.0)) {
            reloadMapImage()
        } completion: {
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
        if let map {
            layouts = database.layouts(for: map)
        }
    }
}
