//
//  MapFavoritesLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapFavoritesLayer: View {

    @Binding var mappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]]
    var spaceSize: Int

    @Binding var width: Int
    @Binding var height: Int

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(mappings.keys), id: \.hashValue) { layout in
                MapFavoriteLayerBlock(
                    layout: layout,
                    colorMap: mappings[layout] ?? [:],
                    spaceSize: spaceSize
                )
            }
            Color.clear
        }
        .frame(
            width: CGFloat(width / zoomDivisor),
            height: CGFloat(height / zoomDivisor)
        )
    }
}
