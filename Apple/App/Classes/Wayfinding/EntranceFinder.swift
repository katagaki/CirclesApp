import CoreGraphics

/// Finds where a walk into a hall starts, working at a quarter of the map's resolution.
/// Every start is the middle of the open white floor at that entrance.
nonisolated struct EntranceFinder {

    static let scale = 4
    static let seal = 61
    static let edgeBand = 40

    let raster: MapRaster
    let fullWidth: Int
    let fullHeight: Int
    let width: Int
    let height: Int
    let tables: [RouteTable]
    let booth: [Bool]
    let walls: [UInt8]
    let white: [Bool]

    init(raster: MapRaster, width fullWidth: Int, height fullHeight: Int, tables: [RouteTable]) {
        let scale = Self.scale
        let width = fullWidth / scale
        let height = fullHeight / scale
        var boothPixels = [Bool](repeating: false, count: fullWidth * fullHeight)
        for table in tables {
            let rect = table.rect.insetBy(dx: -4, dy: -4)
            let minY = max(0, Int(rect.minY)), maxY = min(fullHeight, Int(rect.maxY))
            let minX = max(0, Int(rect.minX)), maxX = min(fullWidth, Int(rect.maxX))
            guard minY < maxY, minX < maxX else { continue }
            for y in minY..<maxY {
                for x in minX..<maxX { boothPixels[y * fullWidth + x] = true }
            }
        }
        var booth = [Bool](repeating: false, count: width * height)
        var walls = [UInt8](repeating: 0, count: width * height)
        var lit = [Bool](repeating: false, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                var hasBooth = false, hasWall = false, allWhite = true
                for pixelY in (y * scale)..<(y * scale + scale) {
                    for pixelX in (x * scale)..<(x * scale + scale) {
                        let index = pixelY * fullWidth + pixelX
                        if boothPixels[index] { hasBooth = true } else if raster.dark[index] > 0 { hasWall = true }
                        if raster.gray[index] < 235 { allWhite = false }
                    }
                }
                booth[y * width + x] = hasBooth
                walls[y * width + x] = hasWall ? 255 : 0
                lit[y * width + x] = allWhite && !hasBooth
            }
        }
        walls = Morphology.dilate(walls, width: width, height: height, kernel: (3, 3))
        self.raster = raster
        self.fullWidth = fullWidth
        self.fullHeight = fullHeight
        self.width = width
        self.height = height
        self.tables = tables
        self.booth = booth
        self.walls = walls
        self.white = lit.indices.map { lit[$0] && walls[$0] == 0 }
    }

    func starts(for entrances: HallEntrances) -> [CGPoint] {
        switch entrances {
        case .signs:
            return []
        case .fixed(let x, let y):
            return [CGPoint(x: x * CGFloat(fullWidth), y: y * CGFloat(fullHeight))]
        case .vestibules:
            return vestibuleStarts()
        case .bottomEdge(let alignsStarts, let requiresClearFloor):
            let starts = bottomEdgeStarts(requiresClearFloor: requiresClearFloor)
            guard alignsStarts, !starts.isEmpty else { return starts }
            let row = starts.map(\.y).sorted()[starts.count / 2]
            return starts.map { CGPoint(x: $0.x, y: row) }
        }
    }

    // MARK: Bottom Edge

    /// Gaps in the bottom edge wide enough to walk through, with floor clear of walls and
    /// booths just inside them.
    private func bottomEdgeStarts(requiresClearFloor: Bool) -> [CGPoint] {
        var starts: [CGPoint] = []
        var runStart: Int?
        func close(at end: Int) {
            defer { runStart = nil }
            guard let start = runStart, end - start + 1 >= 24 else { return }
            if requiresClearFloor && !opensIntoHall(column: (start + end) / 2) { return }
            let point = middle { x, y in x >= start && x <= end && y >= height - Self.edgeBand }
            starts.append(point ?? CGPoint(x: CGFloat((start + end) / 2 * Self.scale), y: CGFloat(fullHeight - 1)))
        }
        for x in 0..<width {
            let isClear = (0..<6).allSatisfy { depth in
                let index = (height - 1 - depth) * width + x
                return walls[index] == 0 && !booth[index]
            }
            if isClear {
                if runStart == nil { runStart = x }
            } else {
                close(at: x - 1)
            }
        }
        close(at: width - 1)
        return starts
    }

    /// Open floor runs straight up from the gap into the hall, rather than into a room drawn
    /// in thin outline beside it.
    private func opensIntoHall(column: Int) -> Bool {
        let center = column * Self.scale
        for depth in 0..<150 {
            let row = fullHeight - 1 - depth
            for x in max(0, center - 6)...min(fullWidth - 1, center + 6) where raster.gray[row * fullWidth + x] < 200 {
                return false
            }
        }
        return true
    }

    // MARK: Vestibules

    /// Sealing every gap in the walls splits the map into halls, which have booths, and open
    /// areas outside them. The gaps the sealing filled between the two are the vestibules,
    /// and each place a vestibule meets a hall is a way in.
    private func vestibuleStarts() -> [CGPoint] {
        let count = width * height
        let sealed = Morphology.erode(
            Morphology.dilate(walls, width: width, height: height, kernel: (Self.seal, Self.seal)),
            width: width, height: height, kernel: (Self.seal, Self.seal)
        )
        let regions = GridLabels.label(sealed.map { $0 == 0 }, rows: height, columns: width)
        var area = [Int](repeating: 0, count: regions.count + 1)
        var booths = [Int](repeating: 0, count: regions.count + 1)
        var touchesEdge = [Bool](repeating: false, count: regions.count + 1)
        for index in 0..<count {
            area[Int(regions.values[index])] += 1
        }
        for table in tables {
            let x = Int(table.rect.midX) / Self.scale, y = Int(table.rect.midY) / Self.scale
            guard x >= 0, y >= 0, x < width, y < height else { continue }
            booths[Int(regions.values[y * width + x])] += 1
        }
        for x in 0..<width {
            touchesEdge[Int(regions.values[x])] = true
            touchesEdge[Int(regions.values[(height - 1) * width + x])] = true
        }
        for y in 0..<height {
            touchesEdge[Int(regions.values[y * width])] = true
            touchesEdge[Int(regions.values[y * width + width - 1])] = true
        }
        var interior = [Bool](repeating: false, count: count)
        var outside = [Bool](repeating: false, count: count)
        for index in 0..<count {
            let region = Int(regions.values[index])
            guard region > 0, area[region] >= 250 || touchesEdge[region] else { continue }
            if booths[region] >= 20 { interior[index] = true } else { outside[index] = true }
        }

        let gaps = (0..<count).map { sealed[$0] > 0 && walls[$0] == 0 }
        let gapLabels = GridLabels.label(gaps, rows: height, columns: width)
        guard gapLabels.count > 0 else { return [] }
        var bounds = [(minX: Int, maxX: Int, minY: Int, maxY: Int)](
            repeating: (Int.max, -1, Int.max, -1), count: gapLabels.count + 1
        )
        var meetsHall = [Int](repeating: 0, count: gapLabels.count + 1)
        var meetsOutside = [Int](repeating: 0, count: gapLabels.count + 1)
        var contact = [UInt8](repeating: 0, count: count)
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let label = Int(gapLabels.values[y * width + x])
                guard label > 0 else { continue }
                bounds[label] = (min(bounds[label].minX, x), max(bounds[label].maxX, x),
                                 min(bounds[label].minY, y), max(bounds[label].maxY, y))
                for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                    let neighbour = (y + dy) * width + x + dx
                    if interior[neighbour] {
                        meetsHall[label] += 1
                        contact[y * width + x] = 255
                    }
                    if outside[neighbour] { meetsOutside[label] += 1 }
                }
            }
        }
        let contacts = GridLabels.label(
            Morphology.dilate(contact, width: width, height: height, kernel: (9, 9)).map { $0 > 0 },
            rows: height, columns: width
        )

        var starts: [CGPoint] = []
        for label in 1...gapLabels.count where meetsHall[label] >= 5 && meetsOutside[label] >= 5 {
            let box = bounds[label]
            var stretches: [Int32: (x: Int, y: Int, cells: Int)] = [:]
            for y in box.minY...box.maxY {
                for x in box.minX...box.maxX where contact[y * width + x] > 0 {
                    let stretch = contacts.values[y * width + x]
                    let sum = stretches[stretch] ?? (0, 0, 0)
                    stretches[stretch] = (sum.x + x, sum.y + y, sum.cells + 1)
                }
            }
            for sum in stretches.values.sorted(by: { $0.x < $1.x }) where sum.cells >= 8 {
                let centerX = sum.x / sum.cells, centerY = sum.y / sum.cells
                let point = middle { x, y in
                    x >= box.minX && x <= box.maxX && y >= box.minY && y <= box.maxY
                        && gaps[y * width + x] && abs(x - centerX) <= 40 && abs(y - centerY) <= 40
                }
                if let point { starts.append(point) }
            }
        }
        return starts
    }

    // MARK: Middle Of The Floor

    /// The white floor cell furthest from anything that is not white floor, among the cells
    /// allowed, in full map pixels.
    private func middle(of allowed: (Int, Int) -> Bool) -> CGPoint? {
        var distance = [Int](repeating: 0, count: width * height)
        for index in distance.indices where white[index] && allowed(index % width, index / width) {
            distance[index] = Int.max / 2
        }
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                guard distance[index] > 0 else { continue }
                distance[index] = min(distance[index], x > 0 ? distance[index - 1] + 1 : 1,
                                      y > 0 ? distance[index - width] + 1 : 1)
            }
        }
        for y in stride(from: height - 1, through: 0, by: -1) {
            for x in stride(from: width - 1, through: 0, by: -1) {
                let index = y * width + x
                guard distance[index] > 0 else { continue }
                distance[index] = min(distance[index], x < width - 1 ? distance[index + 1] + 1 : 1,
                                      y < height - 1 ? distance[index + width] + 1 : 1)
            }
        }
        guard let best = distance.indices.max(by: { distance[$0] < distance[$1] }), distance[best] > 0 else {
            return nil
        }
        let half = Self.scale / 2
        return CGPoint(x: CGFloat(best % width * Self.scale + half), y: CGFloat(best / width * Self.scale + half))
    }
}
