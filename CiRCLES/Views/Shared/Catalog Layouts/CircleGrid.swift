//
//  CircleGrid.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/30.
//

import SwiftUI

struct CircleGrid: View {

    let gridSpacing: CGFloat = 1.0

    var circles: [ComiketCircle]
    var showsOverlayWhenEmpty: Bool = true
    var namespace: Namespace.ID
    var onSelect: ((ComiketCircle) -> Void)

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowWebCut") var showWebCut: Bool

    var body: some View {
        let phoneColumnConfiguration = [GridItem(.adaptive(minimum: 76.0), spacing: gridSpacing)]
        #if targetEnvironment(macCatalyst)
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 80.0), spacing: gridSpacing)]
        #else
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 60.0), spacing: gridSpacing)]
        #endif

        ScrollView {
            LazyVGrid(columns: UIDevice.current.userInterfaceIdiom == .phone ?
                      phoneColumnConfiguration : padOrMacColumnConfiguration,
                      spacing: gridSpacing) {
                ForEach(circles) { circle in
                    Button {
                        onSelect(circle)
                    } label: {
                        CircleCutImage(
                            circle, in: namespace, cutType: .web,
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
