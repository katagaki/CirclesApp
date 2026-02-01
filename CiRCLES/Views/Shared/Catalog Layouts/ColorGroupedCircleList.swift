//
//  ColorGroupedCircleList.swift
//  CiRCLES
//
//  Created by Antigravity on 2026/02/01.
//

import SwiftUI
import TipKit

struct ColorGroupedCircleList: View {

    var groups: [String: [ComiketCircle]]
    var showsOverlayWhenEmpty: Bool = true
    var displayMode: ListDisplayMode
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)
    var onDoubleTap: ((ComiketCircle) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0.0, pinnedViews: [.sectionHeaders]) {
                ForEach(WebCatalogColor.allCases, id: \.self) { color in
                    if let circles = groups[String(color.rawValue)] {
                        Section {
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
                                        .contentShape(Rectangle())
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
                                .background(Rectangle().fill(color.backgroundColor().tertiary))
                                Divider()
                                    .padding([.leading], 100.0)
                                    .background(Rectangle().fill(color.backgroundColor().tertiary))
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if groups.isEmpty && showsOverlayWhenEmpty {
                ContentUnavailableView(
                    "Circles.NoCircles",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Circles.NoCircles.Description")
                )
            }
        }
    }
}
