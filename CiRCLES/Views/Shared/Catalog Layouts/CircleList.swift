//
//  CircleList.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/04.
//

import SwiftUI

struct CircleList: View {

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var displayMode: ListDisplayMode
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)

    var body: some View {
        List(circles) { circle in
            Button {
                onSelect(circle)
            } label: {
                switch displayMode {
                case .regular:
                    CircleListRegularRow(circle: circle, namespace: namespace)
                case .compact:
                    CircleListCompactRow(circle: circle, namespace: namespace)
                }
            }
            .contextMenu(circle: circle) {
                onSelect(circle)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .overlay {
            if circles.isEmpty && showsOverlayWhenEmpty {
                ContentUnavailableView(
                    "Circles.NoCircles",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Circles.NoCircles.Description")
                )
            }
        }
    }
}
