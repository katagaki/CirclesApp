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


    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        let color: Color = !useDarkModeMaps ? .black.opacity(0.3) : .primary.opacity(0.3)
        ZStack(alignment: .topLeading) {
            // Draw selection highlight if popover is active
            if let popoverData = mapper.popoverData {
                Rectangle()
                    .fill(color)
                    .frame(width: popoverData.sourceRect.width, height: popoverData.sourceRect.height)
                    .position(x: popoverData.sourceRect.midX, y: popoverData.sourceRect.midY)
            }
            
            // Interaction layer
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    openMapPopoverIn(x: Int(location.x), y: Int(location.y))
                }
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
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
        for (layout, webCatalogIDs) in mapper.layouts {
            let xMin: Int = Int(Double(layout.positionX))
            let xMax: Int = Int(Double(layout.positionX + spaceSize))
            let yMin: Int = Int(Double(layout.positionY))
            let yMax: Int = Int(Double(layout.positionY + spaceSize))
            if x >= xMin && x < xMax && y >= yMin && y < yMax {
                let spaceSize = Int(Double(spaceSize))
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
