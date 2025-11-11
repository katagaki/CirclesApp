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

    @Binding var canvasSize: CGSize

    @Binding var mappings: [LayoutCatalogMapping: [Int]]
    let spaceSize: Int

    @Binding var popoverLayoutMapping: LayoutCatalogMapping?
    @Binding var popoverWebCatalogIDSet: WebCatalogIDSet?
    @Binding var popoverSourceRect: CGRect

    @AppStorage(wrappedValue: 3, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var namespace: Namespace.ID

    var body: some View {
        Canvas { context, _ in
            // Draw selection highlight if popover is active
            if popoverWebCatalogIDSet != nil {
                let rect = CGRect(
                    x: popoverSourceRect.minX,
                    y: popoverSourceRect.minY,
                    width: popoverSourceRect.width,
                    height: popoverSourceRect.height
                )
                context.fill(
                    Path(rect),
                    with: !useDarkModeMaps ? .color(.black.opacity(0.3)) :
                            .color(.primary.opacity(0.3))
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .contentShape(.rect)
        .onTapGesture { location in
            openMapPopoverIn(x: Int(location.x), y: Int(location.y))
        }
        .overlay {
            // Selection source rectangle for matched transition
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
        let zoomFactor = zoomFactorDouble(zoomDivisor)
        for (layout, webCatalogIDs) in mappings {
            let xMin: Int = Int(Double(layout.positionX) / zoomFactor)
            let xMax: Int = Int(Double(layout.positionX + spaceSize) / zoomFactor)
            let yMin: Int = Int(Double(layout.positionY) / zoomFactor)
            let yMax: Int = Int(Double(layout.positionY + spaceSize) / zoomFactor)
            if x >= xMin && x < xMax && y >= yMin && y < yMax {
                let spaceSize = Int(Double(spaceSize) / zoomFactor)
                popoverSourceRect = CGRect(x: xMin, y: yMin, width: spaceSize, height: spaceSize)
                popoverLayoutMapping = layout
                popoverWebCatalogIDSet = WebCatalogIDSet(ids: webCatalogIDs)
                return
            }
        }
        closeMapPopover()
    }
    // swiftlint:enable identifier_name

    func closeMapPopover() {
        popoverSourceRect = .null
        popoverLayoutMapping = nil
        popoverWebCatalogIDSet = nil
    }
}
