import SwiftUI

struct PinchZoomRowPlacement: Identifiable {
    var section: Int
    var index: Int
    var globalIndex: Int
    var originY: CGFloat

    var id: Int { globalIndex }
}

/// Lays out a sectioned list at any row height between its levels, anchored on the row under the fingers.
struct PinchZoomListSession: PinchZoomSession {
    var startLevel: Int
    var rowHeights: [CGFloat]
    var width: CGFloat
    var sections: [PinchZoomSection]
    var viewport: CGRect
    var anchorSection: Int
    var anchorIndex: Int
    var anchorFraction: CGFloat

    var lower: CGFloat { rowHeights.min() ?? 0.0 }
    var upper: CGFloat { rowHeights.max() ?? 0.0 }

    func itemsTop(section: Int, rowHeight: CGFloat) -> CGFloat {
        sections.prefix(section).reduce(0.0) { $0 + $1.leading + CGFloat($1.count) * rowHeight }
            + sections[section].leading
    }

    func totalHeight(rowHeight: CGFloat) -> CGFloat {
        sections.reduce(0.0) { $0 + $1.leading + CGFloat($1.count) * rowHeight }
    }

    func offset(rowHeight: CGFloat, focusY: CGFloat) -> CGFloat {
        focusY - anchorFraction * rowHeight
            - (itemsTop(section: anchorSection, rowHeight: rowHeight) + CGFloat(anchorIndex) * rowHeight)
    }

    func anchorY(level: Int) -> CGFloat {
        let rowHeight = rowHeights[level]
        return itemsTop(section: anchorSection, rowHeight: rowHeight)
            + (CGFloat(anchorIndex) + anchorFraction) * rowHeight
    }

    func listHeight(level: Int) -> CGFloat {
        totalHeight(rowHeight: rowHeights[level])
    }

    func weight(of level: Int, progress: CGFloat) -> CGFloat {
        let sorted = rowHeights.indices.sorted { rowHeights[$0] < rowHeights[$1] }
        guard let position = sorted.firstIndex(of: level) else { return 0.0 }
        func blend(_ from: Int, _ until: Int) -> CGFloat {
            let start = rowHeights[sorted[from]]
            let end = rowHeights[sorted[until]]
            let fraction = min(max(((progress - start) / (end - start) - 0.35) / 0.3, 0.0), 1.0)
            return fraction.smoothstepped
        }
        var weight = 1.0
        if position > 0, progress < rowHeights[level] {
            weight = progress <= rowHeights[sorted[position - 1]] ? 0.0 : blend(position - 1, position)
        } else if position < sorted.count - 1, progress > rowHeights[level] {
            weight = progress >= rowHeights[sorted[position + 1]] ? 0.0 : 1.0 - blend(position, position + 1)
        }
        return weight
    }

    func snapped(_ progress: CGFloat, velocity: CGFloat) -> Int {
        let levels = rowHeights.indices
        if velocity > 0.5 {
            return levels.filter { rowHeights[$0] >= progress - 0.001 }
                .min(by: { rowHeights[$0] < rowHeights[$1] }) ?? startLevel
        } else if velocity < -0.5 {
            return levels.filter { rowHeights[$0] <= progress + 0.001 }
                .max(by: { rowHeights[$0] < rowHeights[$1] }) ?? startLevel
        }
        return levels.min(by: { abs(rowHeights[$0] - progress) < abs(rowHeights[$1] - progress) }) ?? startLevel
    }

    func contentBottom(progress: CGFloat, focusY: CGFloat) -> CGFloat {
        max(offset(rowHeight: progress, focusY: focusY) + totalHeight(rowHeight: progress), 0.0)
    }

    func headerFrames(progress: CGFloat, focusY: CGFloat) -> [PinchZoomSectionFrame] {
        let offset = offset(rowHeight: progress, focusY: focusY)
        return sections.indices.map { section in
            let top = offset + itemsTop(section: section, rowHeight: progress)
            return PinchZoomSectionFrame(
                id: section,
                header: CGRect(x: 0.0, y: top - sections[section].leading,
                               width: width, height: sections[section].leading),
                items: CGRect(x: 0.0, y: top, width: width, height: CGFloat(sections[section].count) * progress)
            )
        }
    }

    func placements(progress: CGFloat, focusY: CGFloat) -> [PinchZoomRowPlacement] {
        let offset = offset(rowHeight: progress, focusY: focusY)
        var placements: [PinchZoomRowPlacement] = []
        var sectionStart = 0
        for section in sections.indices {
            let count = sections[section].count
            let top = offset + itemsTop(section: section, rowHeight: progress)
            let first = min(max(Int(((viewport.minY - top) / progress).rounded(.down)), 0), count)
            let last = min(max(Int(((viewport.maxY - top) / progress).rounded(.down)) + 1, first), count)
            for index in first..<last {
                placements.append(PinchZoomRowPlacement(section: section, index: index,
                                                        globalIndex: sectionStart + index,
                                                        originY: top + CGFloat(index) * progress))
            }
            sectionStart += count
        }
        return placements
    }
}
