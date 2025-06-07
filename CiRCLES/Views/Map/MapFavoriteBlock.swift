//
//  MapFavoriteBlock.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapFavoriteBlock: View {

    @Environment(\.colorScheme) var colorScheme

    var layout: LayoutCatalogMapping
    var colorMap: [Int: WebCatalogColor?]
    var spaceSize: Int
    var zoomDivisor: Int

    var webCatalogIDs: [Int] {
        Array(colorMap.keys).sorted()
    }

    var body: some View {
        Group {
            switch layout.layoutType {
            case .aOnLeft, .unknown:
                HStack(spacing: 0.0) {
                    favoriteLayout(webCatalogIDs)
                }
            case .aOnBottom:
                VStack(spacing: 0.0) {
                    favoriteLayout(webCatalogIDs.reversed())
                }
            case .aOnRight:
                HStack(spacing: 0.0) {
                    favoriteLayout(webCatalogIDs.reversed())
                }
            case .aOnTop:
                VStack(spacing: 0.0) {
                    favoriteLayout(webCatalogIDs)
                }
            }
        }
        .id(layout.viewID())
        .position(
            x: CGFloat((layout.positionX + Int(spaceSize / 2)) / zoomDivisor),
            y: CGFloat((layout.positionY + Int(spaceSize / 2)) / zoomDivisor)
        )
        .frame(
            width: CGFloat(spaceSize / zoomDivisor),
            height: CGFloat(spaceSize / zoomDivisor),
            alignment: .topLeading
        )
    }

    @ViewBuilder
    func favoriteLayout(_ webCatalogIDs: [Int]?) -> some View {
        ForEach(webCatalogIDs ?? [], id: \.self) { webCatalogID in
            Group {
                if let color = colorMap[webCatalogID], let color {
                    Rectangle()
                        .foregroundStyle(highlightColor(color))
                } else {
                    Rectangle()
                        .foregroundStyle(.primary.opacity(0.001))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func highlightColor(_ color: WebCatalogColor) -> Color {
        switch colorScheme {
        case .light:
            return color.backgroundColor().opacity(0.5)
        case .dark:
            return color.backgroundColor().brightness(0.1).opacity(0.5) as? Color ??
            color.backgroundColor().opacity(0.5)
        @unknown default:
            return color.backgroundColor().opacity(0.5)
        }
    }
}
