//
//  InteractiveMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI

struct InteractiveMap: View {

    @Environment(DatabaseManager.self) var database

    let spaceSize: Int = 40

    @Binding var selectedEventDate: ComiketDate?
    @Binding var selectedMap: ComiketMap?

    @State var mapImage: UIImage?
    @State var circles: [ComiketCircle] = []
    @State var layouts: [ComiketLayout] = []

    @State var zoomDivisor: Int = 1

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
                        .colorInvert(adaptive: true)
                        .overlay {
                            ZStack(alignment: .topLeading) {
                                ForEach(layouts, id: \.self) { layout in
                                    InteractiveMapButton(selectedEventDate: $selectedEventDate, layout: layout)
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
                        VStack(alignment: .center, spacing: 0.0) {
                            Button {
                                withAnimation(.smooth.speed(2.0)) {
                                    zoomDivisor -= 1
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title)
                            }
                            .frame(width: 48.0, height: 48.0, alignment: .center)
                            .contentShape(.rect)
                            .disabled(zoomDivisor <= 1)
                            Divider()
                            Button {
                                withAnimation(.smooth.speed(2.0)) {
                                    zoomDivisor += 1
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title)
                            }
                            .frame(width: 48.0, height: 48.0, alignment: .center)
                            .contentShape(.rect)
                            .disabled(zoomDivisor >= 3)
                        }
                        .frame(maxWidth: 48.0)
                        .background(Material.thin)
                        .clipShape(.rect(cornerRadius: 8.0))
                        .offset(x: -12.0, y: -12.0)
                        .shadow(color: .black.opacity(0.2), radius: 4.0, y: 2.0)
                        Color.clear
                    }
                }
            }
        }
        .onChange(of: selectedMap) { _, _ in
            reloadAll()
        }
    }

    func reloadAll() {
        withAnimation(.snappy.speed(2.0)) {
            reloadMapImage()
        }
        reloadMapLayouts()
        reloadMapCircles()
    }

    func reloadMapImage() {
        if let selectedEventDate, let selectedMap, let selectedHall = ComiketHall(rawValue: selectedMap.filename) {
            mapImage = database.mapImage(
                for: selectedHall,
                on: selectedEventDate.id,
                usingHighDefinition: true
            )
        }
    }

    func reloadMapCircles() {
        if let selectedEventDate {
            circles = database.circles(on: selectedEventDate.id)
        }
    }

    func reloadMapLayouts() {
        if let selectedMap {
            layouts = database.layouts(for: selectedMap)
        }
    }
}
