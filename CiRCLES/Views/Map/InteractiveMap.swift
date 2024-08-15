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
    @Binding var isZoomedToFit: Bool

    @State var mapImage: UIImage?
    @State var circles: [ComiketCircle] = []
    @State var layouts: [ComiketLayout] = []

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                GeometryReader { proxy in
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: mapImage)
                            .resizable()
                            .scaled($isZoomedToFit, to: proxy.size)
                            .colorInvert(adaptive: true)
                            .overlay {
                                if !isZoomedToFit {
                                    ZStack(alignment: .topLeading) {
                                        ForEach(layouts, id: \.self) { layout in
                                            InteractiveMapButton(selectedEventDate: $selectedEventDate, layout: layout)
                                            .position(
                                                x: CGFloat(layout.hdPosition.x + Int(spaceSize / 2)),
                                                y: CGFloat(layout.hdPosition.y + Int(spaceSize / 2))
                                            )
                                            .frame(
                                                width: CGFloat(spaceSize),
                                                height: CGFloat(spaceSize),
                                                alignment: .topLeading
                                            )
                                        }
                                        Color.clear
                                    }
                                }
                            }
                    }
                    .scrollIndicators(.hidden)
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
            circles = database.eventCircles.filter({ $0.day == selectedEventDate.id })
        }
    }

    func reloadMapLayouts() {
        if let selectedMap {
            layouts = database.layouts(for: selectedMap)
        }
    }
}
