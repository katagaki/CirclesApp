//
//  MapFavoritesLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapFavoritesLayer: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(Database.self) var database
    @Environment(Favorites.self) var favorites
    @Environment(Mapper.self) var mapper

    @State var favoritePaths: [WebCatalogColor: Path] = [:]

    let spaceSize: Int

    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(WebCatalogColor.allCases, id: \.self) { color in
                if let path = favoritePaths[color] {
                    path.fill(color.backgroundColor())
                }
            }
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
        .opacity(0.5)
        .allowsHitTesting(false)
        .onAppear {
            Task {
                await reloadFavorites()
            }
        }
        .onChange(of: mapper.layouts) {
            Task.detached {
                await reloadFavorites()
            }
        }
        .onChange(of: favorites.items) {
            Task.detached {
                await reloadFavorites()
            }
        }
    }

    func reloadFavorites() async {
        let actor = DataFetcher(database: database.getTextDatabase())

        let layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(mapper.layouts)

        let webCatalogIDs = Array(Set(layoutFavoriteWebCatalogIDMappings.values.flatMap { $0.keys }))

        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(forWebCatalogIDs: webCatalogIDs)

        // Group by color locally first
        var colorRects: [WebCatalogColor: Path] = [:]

        // Helper to get rect
        func getGenericRect(layout: LayoutCatalogMapping, index: Int, total: Int) -> CGRect {
            let rectWidth: CGFloat
            let rectHeight: CGFloat
            let castSpaceSize = CGFloat(spaceSize)

            // Determine dimensions
            switch layout.layoutType {
            case .aOnLeft, .aOnRight, .unknown:
                rectWidth = castSpaceSize / CGFloat(total)
                rectHeight = castSpaceSize
            case .aOnTop, .aOnBottom:
                rectWidth = castSpaceSize
                rectHeight = castSpaceSize / CGFloat(total)
            }

            let baseX = CGFloat(layout.positionX)
            let baseY = CGFloat(layout.positionY)
            let idx = CGFloat(index)

            if layout.layoutType == .aOnLeft || layout.layoutType == .aOnRight || layout.layoutType == .unknown {
                return CGRect(x: baseX + idx * rectWidth, y: baseY, width: rectWidth, height: rectHeight)
            } else {
                return CGRect(x: baseX, y: baseY + idx * rectHeight, width: rectWidth, height: rectHeight)
            }
        }

        for (layout, mapping) in layoutFavoriteWebCatalogIDMappings {
            // Sort IDs
            let sortedIDs = mapping.keys.sorted()

            // Layout order
            let orderedIDs: [Int]
            switch layout.layoutType {
            case .aOnBottom, .aOnRight:
                orderedIDs = sortedIDs.reversed()
            default:
                orderedIDs = sortedIDs
            }

            let count = orderedIDs.count
            guard count > 0 else { continue }

            for (index, id) in orderedIDs.enumerated() {
                // Remap ID if needed (suffix logic)
                let actualID = spaceNumberSuffixes[id] ?? id
                // Get color from original mapping (since remapping preserves mapping structure conceptually)
                // Actually mapping is [Int (WebCatalogID) : Color?]
                // We need to look up the color for the Original ID
                guard let color = mapping[id], let safeColor = color else { continue }

                let rect = getGenericRect(layout: layout, index: index, total: count)

                // Append to path
                if colorRects[safeColor] == nil {
                    colorRects[safeColor] = Path()
                }
                colorRects[safeColor]?.addRect(rect)
            }
        }

        let finalPaths = colorRects

        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.favoritePaths = finalPaths
            }
        }
    }

    func mapFavoriteMappings(
        _ mappings: [LayoutCatalogMapping: [Int]]
    ) -> [LayoutCatalogMapping: [Int: WebCatalogColor?]] {
        guard let webCatalogIDMappedItems = favorites.wcIDMappedItems else {
            return [:]
        }

        var webCatalogIDToLayout: [Int: LayoutCatalogMapping] = [:]
        for (layout, webCatalogIDs) in mappings {
            for webCatalogID in webCatalogIDs {
                webCatalogIDToLayout[webCatalogID] = layout
            }
        }

        var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
        for (layout, webCatalogIDs) in mappings {
            layoutFavoriteWebCatalogIDMappings[layout] = Dictionary(
                uniqueKeysWithValues: webCatalogIDs.map { ($0, nil) }
            )
        }

        for (webCatalogID, favoriteItem) in webCatalogIDMappedItems {
            if let matchedLayout = webCatalogIDToLayout[webCatalogID] {
                layoutFavoriteWebCatalogIDMappings[matchedLayout]?[webCatalogID] = favoriteItem.favorite.color
            }
        }

        return layoutFavoriteWebCatalogIDMappings
    }
}
