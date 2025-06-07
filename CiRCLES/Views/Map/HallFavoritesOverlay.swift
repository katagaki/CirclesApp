//
//  HallFavoritesOverlay.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct HallFavoritesOverlay: View {

    @Binding var mappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]]
    var spaceSize: Int

    @Binding var width: Int
    @Binding var height: Int
    @Binding var zoomDivisor: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(mappings.keys), id: \.hashValue) { layout in
                MapFavoriteBlock(
                    layout: layout,
                    colorMap: mappings[layout] ?? [:],
                    spaceSize: spaceSize,
                    zoomDivisor: zoomDivisor
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
