//
//  InteractiveMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI

struct InteractiveMap: View {
    @Environment(DatabaseManager.self) var database

    @Binding var selectedEventDate: Int?
    @Binding var selectedHall: ComiketHall?
    @Binding var isZoomedToFit: Bool

    @State var mapImage: UIImage?
    @State var circles: [ComiketCircle] = []

    var body: some View {
        VStack(alignment: .leading) {
            if let mapImage {
                GeometryReader { proxy in
                    ScrollView([.horizontal, .vertical]) {
                        Image(uiImage: mapImage)
                            .resizable()
                            .scaled($isZoomedToFit, to: proxy.size)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .onChange(of: selectedEventDate) { _, _ in
            withAnimation(.snappy.speed(2.0)) {
                reloadMapImage()
            }
            reloadMapCircles()
        }
        .onChange(of: selectedHall) { _, _ in
            withAnimation(.snappy.speed(2.0)) {
                reloadMapImage()
            }
            reloadMapCircles()
        }
    }

    func reloadMapImage() {
        if let selectedEventDate, let selectedHall {
            mapImage = database.mapImage(
                for: selectedHall,
                on: selectedEventDate,
                usingHighDefinition: true
            )
        }
    }

    func reloadMapCircles() {
        circles = database.eventCircles.filter({ $0.day == selectedEventDate })
    }
}
