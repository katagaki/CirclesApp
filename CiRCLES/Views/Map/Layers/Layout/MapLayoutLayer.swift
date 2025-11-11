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

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var namespace: Namespace.ID

    var body: some View {
        Color.clear
            .frame(width: canvasSize.width, height: canvasSize.height)
            .contentShape(.rect)
            .onTapGesture { location in
                openMapPopoverIn(x: Int(location.x), y: Int(location.y))
            }
            .overlay {
                // Selection highlight
                if popoverWebCatalogIDSet != nil {
                    Rectangle()
                        .foregroundStyle(.primary.opacity(0.3))
                        .frame(
                            width: popoverSourceRect.width,
                            height: popoverSourceRect.height
                        )
                        .position(x: popoverSourceRect.midX, y: popoverSourceRect.midY)
                        .transition(.opacity.animation(.smooth.speed(2.0)))
                        .onTapGesture {
                            closeMapPopover()
                        }
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
        closeMapPopover()
    }
    // swiftlint:enable identifier_name

    func closeMapPopover() {
        popoverSourceRect = .null
        popoverLayoutMapping = nil
        popoverWebCatalogIDSet = nil
    }
}
