//
//  MapLayoutLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapLayoutLayer: View {

    @Environment(Database.self) var database
    @Environment(Mapper.self) var mapper
    @Environment(Unifier.self) var unifier

    let spaceSize: Int

    @AppStorage(wrappedValue: 3, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        Canvas { context, _ in
            // Draw selection highlight if popover is active
            if let popoverData = mapper.popoverData {
                context.fill(
                    Path(popoverData.sourceRect),
                    with: !useDarkModeMaps ? .color(.black.opacity(0.3)) :
                            .color(.primary.opacity(0.3))
                )
            }
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
        .contentShape(.rect)
        .onTapGesture { location in
            openMapPopoverIn(x: Int(location.x), y: Int(location.y))
        }
        .overlay {
            // Selection source rectangle for matched transition
            if let popoverData = mapper.popoverData {
                ZStack {}
                    .contentShape(.rect)
                    .frame(width: popoverData.sourceWidth, height: popoverData.sourceHeight)
                    .position(x: popoverData.sourceMidX, y: popoverData.sourceMidY)
            }
        }
    }

    // swiftlint:disable identifier_name
    func openMapPopoverIn(x: Int, y: Int) {
        let zoomFactor = zoomFactorDouble(zoomDivisor)
        for (layout, webCatalogIDs) in mapper.layouts {
            let xMin: Int = Int(Double(layout.positionX) / zoomFactor)
            let xMax: Int = Int(Double(layout.positionX + spaceSize) / zoomFactor)
            let yMin: Int = Int(Double(layout.positionY) / zoomFactor)
            let yMax: Int = Int(Double(layout.positionY + spaceSize) / zoomFactor)
            if x >= xMin && x < xMax && y >= yMin && y < yMax {
                let spaceSize = Int(Double(spaceSize) / zoomFactor)
                let newPopoverData = PopoverData(
                    layout: layout,
                    idSet: WebCatalogIDSet(ids: webCatalogIDs),
                    reversed: layout.layoutType == .aOnBottom || layout.layoutType == .aOnRight,
                    sourceRect: CGRect(x: xMin, y: yMin, width: spaceSize, height: spaceSize)
                )
                if mapper.popoverData == newPopoverData {
                    closeMapPopover()
                } else {
                    mapper.popoverData = newPopoverData
                }
                return
            }
        }
        closeMapPopover()
    }
    // swiftlint:enable identifier_name

    func closeMapPopover() {
        mapper.popoverData = nil
    }
}
