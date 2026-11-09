import CoreGraphics

extension WalkableMap {

    func with(doors: [RouteDoor]) -> WalkableMap {
        WalkableMap(
            rows: rows, columns: columns, walkable: walkable, clearance: clearance,
            stepCost: stepCost, islandLabels: islandLabels, islands: islands, doors: doors
        )
    }

    /// A way in that starts on open floor at the point given.
    func door(startingAt point: CGPoint) -> RouteDoor? {
        guard let cell = nearestWalkable(to: self.cell(at: point)) else { return nil }
        return RouteDoor(cell: cell, sign: CGRect(x: point.x - 1, y: point.y - 1, width: 2, height: 2), edge: .bottom)
    }

    /// Ties a hall sign on the map's edge to the floor just inside it, which is where the
    /// door it names opens into the hall.
    func door(at sign: CGRect) -> RouteDoor? {
        let size = CGFloat(Self.cellSize)
        let width = CGFloat(columns) * size
        let height = CGFloat(rows) * size
        let gaps: [(RouteDoor.Edge, CGFloat)] = [
            (.top, sign.minY), (.bottom, height - sign.maxY), (.left, sign.minX), (.right, width - sign.maxX)
        ]
        guard let edge = gaps.min(by: { $0.1 < $1.1 })?.0 else { return nil }
        let inside: CGPoint
        switch edge {
        case .top: inside = CGPoint(x: sign.midX, y: sign.maxY + size * 3)
        case .bottom: inside = CGPoint(x: sign.midX, y: sign.minY - size * 3)
        case .left: inside = CGPoint(x: sign.maxX + size * 3, y: sign.midY)
        case .right: inside = CGPoint(x: sign.minX - size * 3, y: sign.midY)
        }
        guard let cell = nearestWalkable(to: self.cell(at: inside)) else { return nil }
        return RouteDoor(cell: cell, sign: sign, edge: edge, isSign: true)
    }

    /// Hall signs: solid dark plates with white lettering, set flush against the edge of the
    /// map. Stair and escalator blocks are as dark but sit inside the hall, away from it.
    static func doorSigns(in raster: MapRaster, width: Int, height: Int) -> [CGRect] {
        let closed = Morphology.erode(
            Morphology.dilate(raster.dark, width: width, height: height, kernel: (9, 9)),
            width: width, height: height, kernel: (9, 9)
        )
        let plates = Morphology.open(closed, width: width, height: height, size: 25)
        let labels = GridLabels.label(plates.map { $0 > 0 }, rows: height, columns: width)
        guard labels.count > 0 else { return [] }
        var minX = [Int](repeating: Int.max, count: labels.count + 1)
        var maxX = [Int](repeating: -1, count: labels.count + 1)
        var minY = [Int](repeating: Int.max, count: labels.count + 1)
        var maxY = [Int](repeating: -1, count: labels.count + 1)
        for y in 0..<height {
            for x in 0..<width {
                let label = Int(labels.values[y * width + x])
                guard label > 0 else { continue }
                minX[label] = min(minX[label], x)
                maxX[label] = max(maxX[label], x)
                minY[label] = min(minY[label], y)
                maxY[label] = max(maxY[label], y)
            }
        }
        var signs: [CGRect] = []
        for label in 1...labels.count {
            let boxWidth = maxX[label] - minX[label] + 1
            let boxHeight = maxY[label] - minY[label] + 1
            guard (40...200).contains(boxHeight), (60...260).contains(boxWidth) else { continue }
            let edgeGap = min(minX[label], minY[label], width - 1 - maxX[label], height - 1 - maxY[label])
            guard edgeGap <= 8 else { continue }
            var white = 0
            for y in minY[label]...maxY[label] {
                for x in minX[label]...maxX[label] where raster.gray[y * width + x] > 200 {
                    white += 1
                }
            }
            guard Double(white) / Double(boxWidth * boxHeight) > 0.05 else { continue }
            signs.append(CGRect(x: minX[label], y: minY[label], width: boxWidth, height: boxHeight))
        }
        return signs
    }
}
