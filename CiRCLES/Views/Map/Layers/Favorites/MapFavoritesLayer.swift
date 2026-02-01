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

    @State var favoriteMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]

    let spaceSize: Int

    @AppStorage(wrappedValue: 3, "Map.ZoomDivisor") var zoomDivisor: Int
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
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
        .allowsHitTesting(false)
        .onChange(of: mapper.layouts) {
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

    // swiftlint:disable function_body_length
    func drawFavoritesForLayout(
        context: GraphicsContext,
        layout: LayoutCatalogMapping,
        colorMap: [Int: WebCatalogColor?]
    ) {
        let webCatalogIDs = Array(colorMap.keys).sorted()

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

        // Cache computed values
        let zoomFactor = zoomFactor(zoomDivisor)
        let scaledSpaceSize = CGFloat(spaceSize) / zoomFactor
        let baseX = CGFloat(layout.positionX) / zoomFactor
        let baseY = CGFloat(layout.positionY) / zoomFactor
        let countCGFloat = CGFloat(count)

        // Pre-compute rectangle dimensions based on layout type
        let isHorizontal: Bool
        let rectWidth: CGFloat
        let rectHeight: CGFloat

        switch layout.layoutType {
        case .aOnLeft, .aOnRight, .unknown:
            isHorizontal = true
            rectWidth = scaledSpaceSize / countCGFloat
            rectHeight = scaledSpaceSize
        case .aOnTop, .aOnBottom:
            isHorizontal = false
            rectWidth = scaledSpaceSize
            rectHeight = scaledSpaceSize / countCGFloat
        }

        for (index, webCatalogID) in orderedIDs.enumerated() {
            guard let color = colorMap[webCatalogID], let color else { continue }

            let indexCGFloat = CGFloat(index)
            let rect: CGRect

            if isHorizontal {
                rect = CGRect(
                    x: baseX + indexCGFloat * rectWidth,
                    y: baseY,
                    width: rectWidth,
                    height: rectHeight
                )
            } else {
                rect = CGRect(
                    x: baseX,
                    y: baseY + indexCGFloat * rectHeight,
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
    // swiftlint:enable function_body_length

    func highlightColor(_ color: WebCatalogColor) -> Color {
        let baseColor = color.backgroundColor()
        switch colorScheme {
        case .light:
            return baseColor.opacity(0.5)
        case .dark:
            if useDarkModeMaps {
                return baseColor.brightness(0.1).opacity(0.5) as? Color ?? baseColor.opacity(0.5)
            } else {
                return baseColor.opacity(0.5)
            }
        @unknown default:
            return baseColor.opacity(0.5)
        }
    }

    func reloadFavorites() async {
        database.connect()
        let actor = DataFetcher(database: database.textDatabase)

        let layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(mapper.layouts)

        let webCatalogIDs = Array(Set(layoutFavoriteWebCatalogIDMappings.values.flatMap { $0.keys }))

        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(forWebCatalogIDs: webCatalogIDs)

        let layoutFavoriteWebCatalogIDSorted = layoutFavoriteWebCatalogIDMappings.mapValues { colorMapping in
            colorMapping.reduce(into: [Int: WebCatalogColor?]()) { result, keyValue in
                let remappedID = spaceNumberSuffixes[keyValue.key] ?? keyValue.key
                result[remappedID] = keyValue.value
            }
        }

        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.favoriteMappings = layoutFavoriteWebCatalogIDSorted
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
