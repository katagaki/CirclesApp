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
        ScrollView {
            LazyVStack(spacing: 0.0) {
                ForEach(Array(circles.enumerated()), id: \.element.id) { index, circle in
                    Group {
                        if let onDoubleTap {
                            Group {
                                switch displayMode {
                                case .regular:
                                    CircleListRegularRow(circle: circle, namespace: namespace)
                                case .compact:
                                    CircleListCompactRow(circle: circle, namespace: namespace)
                                }
                            }
                            .contentShape(.rect)
                            .onFastDoubleTap(doubleTap: {
                                onDoubleTap(circle)
                            }, singleTap: {
                                onSelect(circle)
                            })
                            .popoverTip(index == 0 ? DoubleTapVisitTip() : nil)
                        } else {
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
                        }
                    }
                    .padding([.leading, .trailing], 20.0)
                    .padding([.top, .bottom], 10.0)
                    .contextMenu(circle: circle) {
                        onSelect(circle)
                    }
                    switch displayMode {
                    case .regular:
                        Divider()
                            .padding([.leading], 100.0)
                    case .compact:
                        Divider()
                            .padding([.leading], 58.0)
                    }
                }
            }
        }
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
