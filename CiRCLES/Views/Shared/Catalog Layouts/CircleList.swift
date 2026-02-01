//
//  CircleList.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/04.
//

import SwiftUI
import TipKit

struct CircleList: View {

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var displayMode: ListDisplayMode
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)
    var onDoubleTap: ((ComiketCircle) -> Void)?

    var body: some View {
        List(Array(circles.enumerated()), id: \.element.id) { index, circle in
            let row = Button {
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

            Group {
                if let onDoubleTap {
                    row
                        .highPriorityGesture(TapGesture(count: 2).onEnded {
                            onDoubleTap(circle)
                        })
                        .popoverTip(index == 0 ? DoubleTapVisitTip() : nil)
                } else {
                    row
                }
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
