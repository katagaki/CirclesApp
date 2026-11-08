import CoreGraphics
import Foundation

/// Where a visitor can walk on one hall map, as a grid of cells a quarter of a space wide.
///
/// The catalog places every table exactly, but knows nothing of walls, entrances, stages
/// or spaces that were struck out, so those are read off the map image itself.
nonisolated struct WalkableMap: Sendable {

    struct Island: Sendable {
        let name: String
        let minRow: Int
        let maxRow: Int
        let minColumn: Int
        let maxColumn: Int
    }

    static let cellSize: Int = 10

    let rows: Int
    let columns: Int
    let walkable: [Bool]
    let clearance: [Float]
    let stepCost: [Float]
    let islandLabels: [Int32]
    let islands: [Island]
    let doors: [RouteDoor]

    func index(_ point: GridPoint) -> Int { point.row * columns + point.column }

    func contains(_ point: GridPoint) -> Bool {
        point.row >= 0 && point.row < rows && point.column >= 0 && point.column < columns
    }

    func isWalkable(_ point: GridPoint) -> Bool {
        contains(point) && walkable[index(point)]
    }

    func cell(at point: CGPoint) -> GridPoint {
        GridPoint(row: Int(point.y) / Self.cellSize, column: Int(point.x) / Self.cellSize)
    }

    func center(of cell: GridPoint) -> CGPoint {
        let half = CGFloat(Self.cellSize) / 2.0
        return CGPoint(x: CGFloat(cell.column * Self.cellSize) + half, y: CGFloat(cell.row * Self.cellSize) + half)
    }

    func island(at point: GridPoint) -> Island? {
        guard contains(point) else { return nil }
        let label = Int(islandLabels[index(point)])
        return label > 0 ? islands[label - 1] : nil
    }

    func nearestWalkable(to start: GridPoint) -> GridPoint? {
        if isWalkable(start) { return start }
        var seen = Set<GridPoint>([start])
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            for (dy, dx) in [(0, 1), (1, 0), (0, -1), (-1, 0)] {
                let next = GridPoint(row: current.row + dy, column: current.column + dx)
                guard contains(next), seen.insert(next).inserted else { continue }
                if walkable[index(next)] { return next }
                queue.append(next)
            }
        }
        return nil
    }
}

extension WalkableMap {

    static func build(image: CGImage, tables: [RouteTable]) -> WalkableMap? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0, let raster = MapRaster(image: image) else { return nil }

        let thick = Morphology.open(raster.dark, width: width, height: height, size: 7)
        let walls = Morphology.dilate(thick, width: width, height: height, kernel: (5, 5))
        let zones = Morphology.open(raster.fillOrDark, width: width, height: height, size: 31)

        var tableMask = [Bool](repeating: false, count: width * height)
        for table in tables {
            fill(&tableMask, rect: table.rect, width: width, height: height)
        }

        let edges = EdgeDetector.edges(gray: raster.neutralGray, width: width, height: height)
        let enclosed = enclosedRegions(edges: edges, walls: walls, width: width, height: height)

        var blocked = [UInt8](repeating: 0, count: width * height)
        for index in 0..<(width * height)
        where walls[index] > 0 || zones[index] > 0 || tableMask[index] || enclosed[index] > 0 {
            blocked[index] = 255
        }

        let size = cellSize
        let rows = height / size
        let columns = width / size
        var blockedFraction = [Float](repeating: 0.0, count: rows * columns)
        var wallCells = [Bool](repeating: false, count: rows * columns)
        var zoneCells = [Bool](repeating: false, count: rows * columns)
        let cellArea = Float(size * size)
        for row in 0..<rows {
            for column in 0..<columns {
                var blockedCount = 0
                var zoneCount = 0
                var hasWall = false
                for y in (row * size)..<(row * size + size) {
                    let base = y * width
                    for x in (column * size)..<(column * size + size) {
                        if blocked[base + x] > 0 { blockedCount += 1 }
                        if zones[base + x] > 0 { zoneCount += 1 }
                        if walls[base + x] > 0 { hasWall = true }
                    }
                }
                let cell = row * columns + column
                blockedFraction[cell] = Float(blockedCount) / cellArea
                zoneCells[cell] = Float(zoneCount) / cellArea > 0.5
                wallCells[cell] = hasWall
            }
        }

        var interior = hallInterior(walls: wallCells, zones: zoneCells, rows: rows, columns: columns)
        if interior.filter({ $0 }).count < rows * columns / 4 {
            interior = aroundTables(tables, rows: rows, columns: columns)
        }
        var walkable = (0..<(rows * columns)).map { interior[$0] && blockedFraction[$0] < 0.05 }
        walkable = GridLabels.largestComponent(of: walkable, rows: rows, columns: columns)

        let clearance = distanceToObstacle(walkable, rows: rows, columns: columns)
        let stepCost = clearance.map { 1.0 + 3.0 / max($0, 1.0) }
        let (islandLabels, islands) = islandsOf(tables: tables, rows: rows, columns: columns)

        var map = WalkableMap(
            rows: rows, columns: columns, walkable: walkable, clearance: clearance,
            stepCost: stepCost, islandLabels: islandLabels, islands: islands, doors: []
        )
        map = map.with(doors: doorSigns(in: raster, width: width, height: height).compactMap { map.door(at: $0) })
        return map
    }

    private static func fill(_ mask: inout [Bool], rect: CGRect, width: Int, height: Int) {
        let minX = max(0, Int(rect.minX))
        let maxX = min(width, Int(rect.maxX))
        let minY = max(0, Int(rect.minY))
        let maxY = min(height, Int(rect.maxY))
        guard minX < maxX, minY < maxY else { return }
        for y in minY..<maxY {
            for x in minX..<maxX {
                mask[y * width + x] = true
            }
        }
    }

    /// Small regions closed off by edges, such as struck-out spaces and booths missing from
    /// the catalog. The hall itself is open to the image border once walls are ignored.
    private static func enclosedRegions(edges: [Bool], walls: [UInt8], width: Int, height: Int) -> [UInt8] {
        var edgeMask = [UInt8](repeating: 0, count: width * height)
        for index in 0..<(width * height) where edges[index] && walls[index] == 0 {
            edgeMask[index] = 255
        }
        edgeMask = Morphology.dilate(edgeMask, width: width, height: height, kernel: (3, 3))
        let open = edgeMask.map { $0 == 0 }
        let maximumArea = 4 * 40 * 40
        let labels = GridLabels.label(open, rows: height, columns: width)
        var area = [Int](repeating: 0, count: labels.count + 1)
        var touchesBorder = [Bool](repeating: false, count: labels.count + 1)
        for row in 0..<height {
            for column in 0..<width {
                let label = Int(labels.values[row * width + column])
                guard label > 0 else { continue }
                area[label] += 1
                if row == 0 || column == 0 || row == height - 1 || column == width - 1 {
                    touchesBorder[label] = true
                }
            }
        }
        var enclosed = [UInt8](repeating: 0, count: width * height)
        for index in 0..<(width * height) {
            let label = Int(labels.values[index])
            if label > 0 && !touchesBorder[label] && area[label] < maximumArea {
                enclosed[index] = 255
            }
        }
        return Morphology.dilate(enclosed, width: width, height: height, kernel: (5, 5))
    }

    /// Doors leave gaps in the hall outline, so the walls are closed along straight lines
    /// before the outside is flooded in from the image border.
    private static func hallInterior(walls: [Bool], zones: [Bool], rows: Int, columns: Int) -> [Bool] {
        var sealed = walls
        let closings: [((Int, Int), Int)] = [((0, 1), 16), ((1, 0), 16), ((1, 1), 8), ((1, -1), 8)]
        for (direction, length) in closings {
            let closed = GridLabels.closeAlongLine(walls, rows: rows, columns: columns, direction: direction, length: length)
            for index in 0..<sealed.count where closed[index] {
                sealed[index] = true
            }
        }
        let open = (0..<(rows * columns)).map { !sealed[$0] && !zones[$0] }
        let labels = GridLabels.label(open, rows: rows, columns: columns)
        var area = [Int](repeating: 0, count: labels.count + 1)
        var touchesBorder = [Bool](repeating: false, count: labels.count + 1)
        for row in 0..<rows {
            for column in 0..<columns {
                let label = Int(labels.values[row * columns + column])
                guard label > 0 else { continue }
                area[label] += 1
                if row == 0 || column == 0 || row == rows - 1 || column == columns - 1 {
                    touchesBorder[label] = true
                }
            }
        }
        guard let hall = (1...max(labels.count, 1)).filter({ $0 <= labels.count && !touchesBorder[$0] })
            .max(by: { area[$0] < area[$1] }) else {
            return [Bool](repeating: true, count: rows * columns)
        }
        let outsideOfHall = (0..<(rows * columns)).map { Int(labels.values[$0]) != hall }
        let outside = GridLabels.reachableFromBorder(outsideOfHall, rows: rows, columns: columns)
        return outside.map { !$0 }
    }

    /// Where the outline has door gaps too wide to seal, the outside floods into the hall.
    /// The tables' extent, padded out to reach the corridors along the walls, stands in.
    private static func aroundTables(_ tables: [RouteTable], rows: Int, columns: Int) -> [Bool] {
        guard let first = tables.first?.rect else { return [Bool](repeating: true, count: rows * columns) }
        let bounds = tables.reduce(first) { $0.union($1.rect) }
        let pad = 15
        let top = max(0, Int(bounds.minY) / cellSize - pad)
        let bottom = min(rows - 1, Int(bounds.maxY) / cellSize + pad)
        let left = max(0, Int(bounds.minX) / cellSize - pad)
        let right = min(columns - 1, Int(bounds.maxX) / cellSize + pad)
        var interior = [Bool](repeating: false, count: rows * columns)
        for row in top...bottom {
            for column in left...right {
                interior[row * columns + column] = true
            }
        }
        return interior
    }

    private static func distanceToObstacle(_ walkable: [Bool], rows: Int, columns: Int) -> [Float] {
        let far: Float = 1_000_000
        var distance = walkable.map { $0 ? far : 0 }
        let diagonal: Float = 1.41421356
        for row in 0..<rows {
            for column in 0..<columns {
                let index = row * columns + column
                guard distance[index] > 0 else { continue }
                var best = distance[index]
                if row > 0 { best = min(best, distance[index - columns] + 1) }
                if column > 0 { best = min(best, distance[index - 1] + 1) }
                if row > 0 && column > 0 { best = min(best, distance[index - columns - 1] + diagonal) }
                if row > 0 && column < columns - 1 { best = min(best, distance[index - columns + 1] + diagonal) }
                if row == 0 || column == 0 || row == rows - 1 || column == columns - 1 { best = min(best, 1) }
                distance[index] = best
            }
        }
        for row in stride(from: rows - 1, through: 0, by: -1) {
            for column in stride(from: columns - 1, through: 0, by: -1) {
                let index = row * columns + column
                guard distance[index] > 0 else { continue }
                var best = distance[index]
                if row < rows - 1 { best = min(best, distance[index + columns] + 1) }
                if column < columns - 1 { best = min(best, distance[index + 1] + 1) }
                if row < rows - 1 && column < columns - 1 { best = min(best, distance[index + columns + 1] + diagonal) }
                if row < rows - 1 && column > 0 { best = min(best, distance[index + columns - 1] + diagonal) }
                distance[index] = best
            }
        }
        return distance
    }

    private static func islandsOf(tables: [RouteTable], rows: Int, columns: Int) -> ([Int32], [Island]) {
        var occupied = [Bool](repeating: false, count: rows * columns)
        var owners: [(GridPoint, String)] = []
        for table in tables {
            let minRow = max(0, Int(table.rect.minY) / cellSize)
            let maxRow = min(rows - 1, (Int(table.rect.maxY) - 1) / cellSize)
            let minColumn = max(0, Int(table.rect.minX) / cellSize)
            let maxColumn = min(columns - 1, (Int(table.rect.maxX) - 1) / cellSize)
            guard minRow <= maxRow, minColumn <= maxColumn else { continue }
            for row in minRow...maxRow {
                for column in minColumn...maxColumn {
                    occupied[row * columns + column] = true
                }
            }
            owners.append((GridPoint(row: minRow, column: minColumn), table.blockName))
        }
        var grown = occupied
        for row in 0..<rows {
            for column in 0..<columns where occupied[row * columns + column] {
                for dy in -1...1 {
                    for dx in -1...1 {
                        let nextRow = row + dy
                        let nextColumn = column + dx
                        if nextRow >= 0, nextRow < rows, nextColumn >= 0, nextColumn < columns {
                            grown[nextRow * columns + nextColumn] = true
                        }
                    }
                }
            }
        }
        let grownLabels = GridLabels.label(grown, rows: rows, columns: columns)
        var names = [[String: Int]](repeating: [:], count: grownLabels.count + 1)
        for (cell, name) in owners {
            let label = Int(grownLabels.values[cell.row * columns + cell.column])
            names[label][name, default: 0] += 1
        }
        var bounds = [(Int, Int, Int, Int)](repeating: (Int.max, -1, Int.max, -1), count: grownLabels.count + 1)
        var labels = [Int32](repeating: 0, count: rows * columns)
        for row in 0..<rows {
            for column in 0..<columns where occupied[row * columns + column] {
                let label = Int(grownLabels.values[row * columns + column])
                labels[row * columns + column] = Int32(label)
                let current = bounds[label]
                bounds[label] = (min(current.0, row), max(current.1, row), min(current.2, column), max(current.3, column))
            }
        }
        let islands = (1...max(grownLabels.count, 1)).compactMap { label -> Island? in
            guard label <= grownLabels.count else { return nil }
            let box = bounds[label]
            let name = names[label].max(by: { $0.value < $1.value })?.key ?? ""
            return Island(name: name, minRow: box.0, maxRow: box.1, minColumn: box.2, maxColumn: box.3)
        }
        return (labels, islands)
    }
}
