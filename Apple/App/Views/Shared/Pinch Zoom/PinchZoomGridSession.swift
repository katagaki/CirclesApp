import SwiftUI

struct PinchZoomMorph {
    var fewerColumns: Int
    var moreColumns: Int
    var blend: CGFloat
    var cellWidth: CGFloat
    var cellHeight: CGFloat
    var columnPitch: CGFloat
    var rowPitch: CGFloat
}

struct PinchZoomPlacement: Identifiable {
    var section: Int
    var index: Int
    var globalIndex: Int
    var isGhost: Bool
    var origin: CGPoint
    var opacity: CGFloat

    var id: Int { globalIndex * 2 + (isGhost ? 1 : 0) }
}

struct PinchZoomSectionFrame: Identifiable {
    var id: Int
    var header: CGRect
    var items: CGRect
}

/// Lays out a sectioned grid partway between two column counts, anchored on the item under the fingers.
struct PinchZoomGridSession: PinchZoomSession {
    var startCount: Int
    var columnCounts: [Int]
    var width: CGFloat
    var spacing: CGFloat
    var heightRatio: CGFloat
    var sections: [PinchZoomSection]
    var viewport: CGRect
    var anchorSection: Int
    var anchorIndex: Int
    var anchorFraction: CGFloat

    var lower: Int { columnCounts.first ?? startCount }
    var upper: Int { columnCounts.last ?? startCount }

    func cellWidth(columns: CGFloat) -> CGFloat {
        max((width - spacing * (columns - 1.0)) / columns, 1.0)
    }

    func cellHeight(columns: CGFloat) -> CGFloat {
        cellWidth(columns: columns) * heightRatio
    }

    func columns(forCellWidth cellWidth: CGFloat) -> CGFloat {
        (width + spacing) / (cellWidth + spacing)
    }

    func rowPitch(columns: Int) -> CGFloat {
        cellHeight(columns: CGFloat(columns)) + spacing
    }

    func itemsHeight(count: Int, columns: Int, rowPitch: CGFloat) -> CGFloat {
        let rows = (count + columns - 1) / columns
        return rows == 0 ? 0.0 : CGFloat(rows) * rowPitch - spacing
    }

    func itemsTop(section: Int, columns: Int, rowPitch: CGFloat) -> CGFloat {
        var top = 0.0
        for earlier in sections.prefix(section) {
            top += earlier.leading + itemsHeight(count: earlier.count, columns: columns, rowPitch: rowPitch)
        }
        return top + sections[section].leading
    }

    func totalHeight(columns: Int, rowPitch: CGFloat) -> CGFloat {
        sections.reduce(0.0) { $0 + $1.leading + itemsHeight(count: $1.count, columns: columns, rowPitch: rowPitch) }
    }

    func anchorY(columns: Int) -> CGFloat {
        let rowPitch = rowPitch(columns: columns)
        return itemsTop(section: anchorSection, columns: columns, rowPitch: rowPitch)
            + CGFloat(anchorIndex / columns) * rowPitch
            + anchorFraction * cellHeight(columns: CGFloat(columns))
    }

    func gridHeight(columns: Int) -> CGFloat {
        totalHeight(columns: columns, rowPitch: rowPitch(columns: columns))
    }

    func snapped(_ progress: CGFloat, velocity: CGFloat) -> Int {
        if velocity > 0.5 {
            return columnCounts.last(where: { CGFloat($0) <= progress + 0.001 }) ?? lower
        } else if velocity < -0.5 {
            return columnCounts.first(where: { CGFloat($0) >= progress - 0.001 }) ?? upper
        }
        return columnCounts.min(by: { abs(CGFloat($0) - progress) < abs(CGFloat($1) - progress) }) ?? startCount
    }

    func morph(progress: CGFloat) -> PinchZoomMorph {
        let fewer = columnCounts.last(where: { CGFloat($0) <= progress }) ?? lower
        let more = columnCounts.first(where: { $0 > fewer }) ?? fewer
        let fraction = more == fewer ? 0.0 :
            min(max(((progress - CGFloat(fewer)) / CGFloat(more - fewer) - 0.35) / 0.3, 0.0), 1.0)
        let cellWidth = cellWidth(columns: progress)
        let cellHeight = cellWidth * heightRatio
        return PinchZoomMorph(fewerColumns: fewer,
                              moreColumns: more,
                              blend: fraction.smoothstepped,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                              columnPitch: cellWidth + spacing,
                              rowPitch: cellHeight + spacing)
    }

    func offset(columns: Int, morph: PinchZoomMorph, focusY: CGFloat) -> CGFloat {
        let anchorTop = itemsTop(section: anchorSection, columns: columns, rowPitch: morph.rowPitch)
            + CGFloat(anchorIndex / columns) * morph.rowPitch
        return focusY - anchorFraction * morph.cellHeight - anchorTop
    }

    func cellOrigin(section: Int, index: Int, columns: Int, morph: PinchZoomMorph, offset: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(index % columns) * morph.columnPitch,
                y: offset + itemsTop(section: section, columns: columns, rowPitch: morph.rowPitch)
                    + CGFloat(index / columns) * morph.rowPitch)
    }

    func visibleItems(section: Int, columns: Int, morph: PinchZoomMorph, offset: CGFloat) -> Range<Int> {
        let count = sections[section].count
        let top = offset + itemsTop(section: section, columns: columns, rowPitch: morph.rowPitch)
        let firstRow = max(Int(((viewport.minY - top) / morph.rowPitch).rounded(.down)), 0)
        let lastRow = Int(((viewport.maxY - top) / morph.rowPitch).rounded(.down))
        guard lastRow >= firstRow else { return 0..<0 }
        let first = min(firstRow * columns, count)
        let last = min(max((lastRow + 1) * columns, first), count)
        return first..<last
    }

    func contentBottom(progress: CGFloat, focusY: CGFloat) -> CGFloat {
        let morph = morph(progress: progress)
        func bottom(columns: Int) -> CGFloat {
            offset(columns: columns, morph: morph, focusY: focusY)
                + totalHeight(columns: columns, rowPitch: morph.rowPitch)
        }
        let fewer = bottom(columns: morph.fewerColumns)
        let more = bottom(columns: morph.moreColumns)
        return max(fewer + (more - fewer) * morph.blend, 0.0)
    }

    func sectionFrames(progress: CGFloat, focusY: CGFloat) -> [PinchZoomSectionFrame] {
        let morph = morph(progress: progress)
        let fewerOffset = offset(columns: morph.fewerColumns, morph: morph, focusY: focusY)
        let moreOffset = offset(columns: morph.moreColumns, morph: morph, focusY: focusY)
        return sections.indices.map { section in
            func frames(columns: Int, offset: CGFloat) -> CGRect {
                let top = offset + itemsTop(section: section, columns: columns, rowPitch: morph.rowPitch)
                let height = itemsHeight(count: sections[section].count, columns: columns, rowPitch: morph.rowPitch)
                return CGRect(x: 0.0, y: top, width: width, height: height)
            }
            let fewer = frames(columns: morph.fewerColumns, offset: fewerOffset)
            let more = frames(columns: morph.moreColumns, offset: moreOffset)
            let blend = { (start: CGFloat, end: CGFloat) in start + (end - start) * morph.blend }
            let top = blend(fewer.minY, more.minY)
            return PinchZoomSectionFrame(
                id: section,
                header: CGRect(x: 0.0, y: top - sections[section].leading,
                               width: width, height: sections[section].leading),
                items: CGRect(x: 0.0, y: top, width: width, height: blend(fewer.height, more.height))
            )
        }
    }

    func placements(progress: CGFloat, focusY: CGFloat) -> [PinchZoomPlacement] {
        let morph = morph(progress: progress)
        let fewerOffset = offset(columns: morph.fewerColumns, morph: morph, focusY: focusY)
        let moreOffset = offset(columns: morph.moreColumns, morph: morph, focusY: focusY)
        var placements: [PinchZoomPlacement] = []
        var sectionStart = 0
        for section in sections.indices {
            let fewerItems = visibleItems(section: section, columns: morph.fewerColumns,
                                          morph: morph, offset: fewerOffset)
            let moreItems = visibleItems(section: section, columns: morph.moreColumns,
                                         morph: morph, offset: moreOffset)
            let ranges = [fewerItems, moreItems].filter { !$0.isEmpty }
            if let first = ranges.map(\.lowerBound).min(), let last = ranges.map(\.upperBound).max() {
                for index in first..<last {
                    let start = cellOrigin(section: section, index: index, columns: morph.fewerColumns,
                                           morph: morph, offset: fewerOffset)
                    let end = cellOrigin(section: section, index: index, columns: morph.moreColumns,
                                         morph: morph, offset: moreOffset)
                    let globalIndex = sectionStart + index
                    if abs(end.x - start.x) > morph.columnPitch * 1.5 {
                        placements.append(PinchZoomPlacement(section: section, index: index,
                                                             globalIndex: globalIndex, isGhost: false,
                                                             origin: start, opacity: 1.0 - morph.blend))
                        placements.append(PinchZoomPlacement(section: section, index: index,
                                                             globalIndex: globalIndex, isGhost: true,
                                                             origin: end, opacity: morph.blend))
                    } else {
                        placements.append(PinchZoomPlacement(
                            section: section, index: index, globalIndex: globalIndex, isGhost: false,
                            origin: CGPoint(x: start.x + (end.x - start.x) * morph.blend,
                                            y: start.y + (end.y - start.y) * morph.blend),
                            opacity: 1.0
                        ))
                    }
                }
            }
            sectionStart += sections[section].count
        }
        return placements
    }
}
