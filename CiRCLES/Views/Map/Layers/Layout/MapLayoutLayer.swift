//
//  MapLayoutLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapLayoutLayer: View {

    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    var image: UIImage
    @Binding var mappings: [LayoutCatalogMapping: [Int]]
    var spaceSize: Int

    @Binding var width: Int
    @Binding var height: Int
    @Binding var zoomDivisor: Int

    @Binding var popoverLayoutMapping: LayoutCatalogMapping?
    @Binding var popoverWebCatalogIDSet: WebCatalogIDSet?
    @Binding var popoverSourceRect: CGRect

    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var namespace: Namespace.ID

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(
                width: CGFloat(width / zoomDivisor),
                height: CGFloat(height / zoomDivisor)
            )
            .animation(.smooth.speed(2.0), value: zoomDivisor)
            .colorInvert(adaptive: true, enabled: $useDarkModeMaps)
            .onTapGesture { location in
                openMapPopoverIn(x: Int(location.x), y: Int(location.y))
            }
            .overlay {
                // Selection highlight
                if let popoverWebCatalogIDSet {
                    Rectangle()
                        .foregroundStyle(.primary.opacity(0.3))
                        .frame(
                            width: popoverSourceRect.width,
                            height: popoverSourceRect.height
                        )
                        .position(x: popoverSourceRect.midX, y: popoverSourceRect.midY)
                        .transition(.opacity.animation(.smooth.speed(2.0)))
                }
            }
            .overlay {
                // Scroll anchor for popover
                if let popoverWebCatalogIDSet {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .position(x: popoverSourceRect.midX, y: popoverSourceRect.midY)
                        .id(popoverWebCatalogIDSet.id)
                }
            }
            .overlay {
                // Selection source rectangle
                if let popoverLayoutMapping {
                    ZStack {}
                        .contentShape(.rect)
                        .matchedTransitionSource(
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
                return
            }
        }
        popoverSourceRect = .null
        popoverLayoutMapping = nil
        popoverWebCatalogIDSet = nil
    }
    // swiftlint:enable identifier_name
}
