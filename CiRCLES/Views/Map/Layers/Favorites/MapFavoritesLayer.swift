//
//  MapFavoritesLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import SwiftUI

struct MapFavoritesLayer: View {

    @Environment(Favorites.self) var favorites
    @Environment(\.colorScheme) var colorScheme

    @Binding var canvasSize: CGSize

    @Binding var mappings: [LayoutCatalogMapping: [Int]]
    @State var favoriteMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]

    let spaceSize: Int

    @AppStorage(wrappedValue: 1, "Map.ZoomDivisor") var zoomDivisor: Int
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var body: some View {
        Canvas { context, _ in
            for (layout, colorMap) in favoriteMappings {
                drawFavoritesForLayout(
                    context: context,
                    layout: layout,
                    colorMap: colorMap
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
        .onChange(of: mappings) {
            favoriteMappings.removeAll()
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

    func drawFavoritesForLayout(
        context: GraphicsContext,
        layout: LayoutCatalogMapping,
        colorMap: [Int: WebCatalogColor?]
    ) {
        let webCatalogIDs = Array(colorMap.keys).sorted()
        let scaledSpaceSize = CGFloat(spaceSize) / CGFloat(zoomDivisor)

        // Determine if we need to reverse the order based on layout type
        let orderedIDs: [Int]
        switch layout.layoutType {
        case .aOnLeft, .aOnTop, .unknown:
            orderedIDs = webCatalogIDs
        case .aOnBottom, .aOnRight:
            orderedIDs = webCatalogIDs.reversed()
        }

        let count = orderedIDs.count
        guard count > 0 else { return }

        // Calculate the base position (center of the layout)
        let baseX = CGFloat(layout.positionX) / CGFloat(zoomDivisor)
        let baseY = CGFloat(layout.positionY) / CGFloat(zoomDivisor)

        for (index, webCatalogID) in orderedIDs.enumerated() {
            guard let color = colorMap[webCatalogID], let color else { continue }

            let rect: CGRect

            switch layout.layoutType {
            case .aOnLeft, .aOnRight, .unknown:
                // Horizontal layout - divide width
                let rectWidth = scaledSpaceSize / CGFloat(count)
                let rectHeight = scaledSpaceSize
                let offsetX = CGFloat(index) * rectWidth
                rect = CGRect(
                    x: baseX + offsetX,
                    y: baseY,
                    width: rectWidth,
                    height: rectHeight
                )
            case .aOnTop, .aOnBottom:
                // Vertical layout - divide height
                let rectWidth = scaledSpaceSize
                let rectHeight = scaledSpaceSize / CGFloat(count)
                let offsetY = CGFloat(index) * rectHeight
                rect = CGRect(
                    x: baseX,
                    y: baseY + offsetY,
                    width: rectWidth,
                    height: rectHeight
                )
            }

            context.fill(
                Path(rect),
                with: .color(highlightColor(color))
            )
        }
    }

    func highlightColor(_ color: WebCatalogColor) -> Color {
        switch colorScheme {
        case .light:
            return color.backgroundColor().opacity(0.5)
        case .dark:
            if useDarkModeMaps {
                return color.backgroundColor().brightness(0.1).opacity(0.5) as? Color ??
                color.backgroundColor().opacity(0.5)
            } else {
                return color.backgroundColor().opacity(0.5)
            }
        @unknown default:
            return color.backgroundColor().opacity(0.5)
        }
    }

    func reloadFavorites() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        // Create favorites mapping for Web Catalog IDs
        let layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(
            mappings
        )
        // List out all Web Catalog IDs
        let webCatalogIDs: [Int] = Array(Set(
            layoutFavoriteWebCatalogIDMappings.values
                .reduce(into: [] as [Int]) { result, webCatalogIDs in
                    result.append(contentsOf: webCatalogIDs.keys)
                }
        ))
        // Map all Web Catalog IDs to space number suffixes
        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(
            forWebCatalogIDs: webCatalogIDs
        )
        // Replace Web Catalog IDs with space number suffixes
        let layoutFavoriteWebCatalogIDSorted = layoutFavoriteWebCatalogIDMappings
            .reduce(into: [LayoutCatalogMapping: [Int: WebCatalogColor?]]()) { result, keyValue in
                let mapping = keyValue.key
                let colorMapping = keyValue.value
                result[mapping] = colorMapping
                    .reduce(into: [Int: WebCatalogColor?]()) { result, keyValue in
                        let webCatalogID = keyValue.key
                        let color = keyValue.value
                        result[spaceNumberSuffixes[webCatalogID] ?? webCatalogID] = color
                    }
            }

        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.favoriteMappings = layoutFavoriteWebCatalogIDSorted
            }
        }
    }

    func mapFavoriteMappings(
        _ layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]]
    ) -> [LayoutCatalogMapping: [Int: WebCatalogColor?]] {
        var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
        if let webCatalogIDMappedItems = favorites.wcIDMappedItems {
            for (webCatalogID, favoriteItem) in webCatalogIDMappedItems {
                // 1. Find the layout catalog mapping that matches the Web Catalog ID
                let matchingLayoutMaps: [LayoutCatalogMapping: [Int]] = layoutWebCatalogIDMappings
                    .filter { $1.contains(webCatalogID) }

                // 2. Ensure that only one layout is selected
                if let (matchedLayoutMap, _) = matchingLayoutMaps.first {
                    // 3. Set up the sub-dictionary for the favorites mapping
                    if layoutFavoriteWebCatalogIDMappings[matchedLayoutMap] == nil {
                        let webCatalogIDs = layoutWebCatalogIDMappings[matchedLayoutMap] ?? []
                        layoutFavoriteWebCatalogIDMappings[matchedLayoutMap] = webCatalogIDs
                            .reduce(into: [:]) { partialResult, webCatalogID in
                                let nilColor: WebCatalogColor? = nil
                                partialResult[webCatalogID] = nilColor
                            }
                    }

                    // 4. Set the color for the Web Catalog ID in the favorites mapping
                    layoutFavoriteWebCatalogIDMappings[matchedLayoutMap]?[webCatalogID] = favoriteItem.favorite.color
                }
            }
            // 5. Change keys to space sub number to force MapFavoriteLayerBlock to sort correctly
            // TODO
        }
        return layoutFavoriteWebCatalogIDMappings
    }
}
