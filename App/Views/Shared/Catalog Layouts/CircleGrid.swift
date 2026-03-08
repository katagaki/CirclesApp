//
//  CircleGrid.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/30.
//

import SwiftUI
import TipKit

struct CircleGrid: View {

    let gridSpacing: CGFloat = 1.0

    var displayMode: GridDisplayMode = .medium
    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)
    var onDoubleTap: ((ComiketCircle) -> Void)?

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    var body: some View {
        let phoneColumnConfiguration = [GridItem(.adaptive(minimum: {
            switch displayMode {
            case .big: return 110.0
            case .medium: return 76.0
            case .small: return 48.0
            }
        }()), spacing: gridSpacing)]
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: {
            switch displayMode {
            case .big: return 100.0
            case .medium: return 68.0
            case .small: return 44.0
            }
        }()), spacing: gridSpacing)]

        ScrollView {
            LazyVGrid(columns: UIDevice.current.userInterfaceIdiom == .phone ?
                      phoneColumnConfiguration : padOrMacColumnConfiguration,
                      spacing: gridSpacing) {
                ForEach(Array(circles.enumerated()), id: \.element.id) { index, circle in
                    if let onDoubleTap {
                        CircleCutImage(
                            circle, in: namespace, cutType: showWebCut ? .web : .catalog,
                            displayMode: displayMode,
                            showSpaceName: $showSpaceName, showDay: $showDay
                        )
                        .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
                        .onFastDoubleTap(doubleTap: {
                            onDoubleTap(circle)
                        }, singleTap: {
                            onSelect(circle)
                        })
                        .contextMenu(circle: circle) {
                            onSelect(circle)
                        }
                        .matchedTransitionSource(id: circle.id, in: namespace)
                        .popoverTip(index == 0 ? DoubleTapVisitTip() : nil)
                    } else {
                        Button {
                            onSelect(circle)
                        } label: {
                            CircleCutImage(
                                circle, in: namespace, cutType: showWebCut ? .web : .catalog,
                                displayMode: displayMode,
                                showSpaceName: $showSpaceName, showDay: $showDay
                            )
                            .matchedGeometryEffect(id: "\(circle.id).Cut", in: namespace)
                        }
                        .contextMenu(circle: circle) {
                            onSelect(circle)
                        }
                        .matchedTransitionSource(id: circle.id, in: namespace)
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
