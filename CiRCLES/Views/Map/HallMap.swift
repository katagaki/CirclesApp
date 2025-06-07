//
//  HallMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct HallMap: View {

    var image: UIImage
    @Binding var mappings: [LayoutCatalogMapping: [Int]]
    var spaceSize: Int

    @Binding var width: Int
    @Binding var height: Int
    @Binding var zoomDivisor: Int

    @State var popoverLayoutMapping: LayoutCatalogMapping?
    @State var popoverWebCatalogIDSet: WebCatalogIDSet?
    @State var popoverSourceRect: CGRect = .null

    var namespace: Namespace.ID

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(
                width: CGFloat(width / zoomDivisor),
                height: CGFloat(height / zoomDivisor)
            )
            .padding(.trailing, 72.0)
            .animation(.smooth.speed(2.0), value: zoomDivisor)
            .colorInvert(adaptive: true)
            .onTapGesture { location in
                if popoverWebCatalogIDSet == nil {
                    openMapPopoverIn(x: Int(location.x), y: Int(location.y))
                }
            }
            .popover(
                item: $popoverWebCatalogIDSet,
                attachmentAnchor: .rect(.rect(popoverSourceRect))
            ) { _ in
                InteractiveMapDetailPopover(webCatalogIDSet: $popoverWebCatalogIDSet)
            }
            .overlay {
                // Selection highlight
                if popoverWebCatalogIDSet != nil {
                    Rectangle()
                        .foregroundStyle(Color.accent.opacity(0.3))
                        .frame(
                            width: popoverSourceRect.width,
                            height: popoverSourceRect.height
                        )
                        .position(x: popoverSourceRect.midX, y: popoverSourceRect.midY)
                        .transition(.opacity.animation(.smooth.speed(2.0)))
                }
            }
            .overlay {
                // Selection highlight
                if let popoverLayoutMapping {
                    Rectangle()
                        .foregroundStyle(.primary.opacity(0.001))
                        .automaticMatchedTransitionSource(
                            id: "Layout.\(popoverLayoutMapping.blockID).\(popoverLayoutMapping.spaceNumber)",
                            in: namespace
                        )
                        .frame(
                            width: popoverSourceRect.width,
                            height: popoverSourceRect.height
                        )
                        .position(x: popoverSourceRect.midX, y: popoverSourceRect.midY)
                }
            }
    }

    // swiftlint:disable identifier_name
    func openMapPopoverIn(x: Int, y: Int) {
        for (layout, webCatalogIDs) in mappings {
            let xMin: Int = layout.positionX / zoomDivisor
            let xMax: Int = (layout.positionX + spaceSize) / zoomDivisor
            let yMin: Int = layout.positionY / zoomDivisor
            let yMax: Int = (layout.positionY + spaceSize) / zoomDivisor
            if x >= xMin && x < xMax && y >= yMin && y < yMax {
                let spaceSize = spaceSize / zoomDivisor
                popoverSourceRect = CGRect(x: xMin, y: yMin, width: spaceSize, height: spaceSize)
                popoverLayoutMapping = layout
                popoverWebCatalogIDSet = WebCatalogIDSet(ids: webCatalogIDs)
                break
            }
        }
    }
    // swiftlint:enable identifier_name
}
