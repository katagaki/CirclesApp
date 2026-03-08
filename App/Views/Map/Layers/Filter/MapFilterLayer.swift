//
//  MapFilterLayer.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/03/08.
//

import SwiftUI
import AXiS

struct MapFilterLayer: View {

    @Environment(\.colorScheme) var colorScheme
    @Environment(Database.self) var database
    @Environment(Mapper.self) var mapper
    @Environment(UserSelections.self) var selections

    @State var dimPath: Path = Path()

    let spaceSize: Int

    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool

    var isFilterActive: Bool {
        !selections.genres.isEmpty || !selections.blocks.isEmpty
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isFilterActive {
                let isDarkMap = colorScheme == .dark && useDarkModeMaps
                dimPath.fill(isDarkMap ? Color.black.opacity(0.8) : Color.white.opacity(0.85))
            }
        }
        .frame(width: mapper.canvasSize.width, height: mapper.canvasSize.height)
        .allowsHitTesting(false)
        .onChange(of: mapper.layouts) {
            Task.detached {
                await reloadFilterOverlay()
            }
        }
        .onChange(of: selections.catalogSelectionID) {
            Task.detached {
                await reloadFilterOverlay()
            }
        }
    }

    func reloadFilterOverlay() async {
        guard isFilterActive else {
            await MainActor.run {
                withAnimation(.smooth.speed(2.0)) {
                    self.dimPath = Path()
                }
            }
            return
        }

        let actor = DataFetcher(database: database.getTextDatabase())

        let selectedGenreIDs = selections.genres.isEmpty ? nil :
            Array(selections.genres.map { $0.id })
        let selectedMapID = selections.map?.id
        let selectedBlockIDs = selections.blocks.isEmpty ? nil :
            Array(selections.blocks.map { $0.id })
        let selectedDayID = selections.date?.id

        let filteredWCIDs = await actor.filteredWebCatalogIDs(
            inMap: selectedMapID,
            withGenre: selectedGenreIDs,
            inBlock: selectedBlockIDs,
            onDay: selectedDayID
        )

        let allLayoutWCIDs = Array(Set(mapper.layouts.values.flatMap { $0 }))
        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(forWebCatalogIDs: allLayoutWCIDs)

        var newPath = Path()

        for (layout, layoutWCIDs) in mapper.layouts {
            let sortedIDs = layoutWCIDs.sorted {
                let lhsSuffix = spaceNumberSuffixes[$0] ?? 0
                let rhsSuffix = spaceNumberSuffixes[$1] ?? 0
                return lhsSuffix < rhsSuffix
            }
            let orderedIDs: [Int]
            switch layout.layoutType {
            case .aOnBottom, .aOnRight:
                orderedIDs = sortedIDs.reversed()
            default:
                orderedIDs = sortedIDs
            }

            let count = orderedIDs.count
            guard count > 0 else { continue }

            for (index, id) in orderedIDs.enumerated() where !filteredWCIDs.contains(id) {
                let rect = getGenericRect(layout: layout, index: index, total: count)
                newPath.addRect(rect)
            }
        }

        let finalPath = newPath
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.dimPath = finalPath
            }
        }
    }

    func getGenericRect(layout: LayoutCatalogMapping, index: Int, total: Int) -> CGRect {
        let rectWidth: CGFloat
        let rectHeight: CGFloat
        let castSpaceSize = CGFloat(spaceSize)

        switch layout.layoutType {
        case .aOnLeft, .aOnRight, .unknown:
            rectWidth = (castSpaceSize / CGFloat(total)) + 1
            rectHeight = castSpaceSize + 1
        case .aOnTop, .aOnBottom:
            rectWidth = castSpaceSize + 1
            rectHeight = (castSpaceSize / CGFloat(total)) + 1
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
}
