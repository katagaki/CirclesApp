import CoreGraphics

nonisolated enum RoutePlanner {

    static func plan(
        map baseMap: WalkableMap, stops requests: [RouteStopRequest], origin: CGPoint?,
        closures: [RouteClosure] = [], halls: [RouteHall] = []
    ) -> PlannedRoute? {
        var closureLines: [RouteClosureLine] = []
        var blockedCells: [GridPoint] = []
        for closure in closures where closure.isActive {
            if let boundaryX = closure.hallBoundaryX {
                let cells = baseMap.boundaryCells(atX: boundaryX)
                blockedCells += cells
                let rows = cells.map(\.row)
                if let top = rows.min(), let bottom = rows.max() {
                    let size = CGFloat(WalkableMap.cellSize)
                    closureLines.append(RouteClosureLine(
                        id: closure.id,
                        from: CGPoint(x: boundaryX, y: CGFloat(top) * size),
                        to: CGPoint(x: boundaryX, y: CGFloat(bottom + 1) * size)
                    ))
                }
                continue
            }
            let cells = baseMap.closureCells(at: closure.point, across: closure.across)
            blockedCells += cells
            if let line = line(through: cells, in: baseMap) {
                closureLines.append(RouteClosureLine(id: closure.id, from: line.0, to: line.1))
            }
        }
        let map = baseMap.blocking(blockedCells)
        var pathfinder = Pathfinder(map: map)
        let boundaries = zip(halls, halls.dropFirst()).map { ($0.rect.maxX + $1.rect.minX) / 2.0 }
        let doors = map.doors.filter { door in
            !boundaries.contains { abs($0 - door.sign.midX) < 160.0 }
        }
        pathfinder.portals = portals(between: doors, in: map)
        let doorsByCell = Dictionary(doors.map { (map.index($0.cell), $0) }, uniquingKeysWith: { first, _ in first })
        let doorName: (GridPoint) -> String = { cell in
            guard let door = doorsByCell[map.index(cell)] else { return "" }
            return halls.first { $0.rect.minX <= door.sign.midX && door.sign.midX < $0.rect.maxX }?.name ?? ""
        }
        let outside: (GridPoint, GridPoint) -> [CGPoint] = { from, to in
            guard let exit = doorsByCell[map.index(from)], let entry = doorsByCell[map.index(to)] else {
                return [map.center(of: from), map.center(of: to)]
            }
            return [map.center(of: from), CGPoint(x: exit.sign.midX, y: exit.sign.midY),
                    CGPoint(x: entry.sign.midX, y: entry.sign.midY), map.center(of: to)]
        }
        var candidates: [(request: RouteStopRequest, cell: GridPoint)] = []
        for request in requests {
            if let cell = accessCell(for: request, in: map) {
                candidates.append((request, cell))
            }
        }
        guard !candidates.isEmpty else { return nil }

        let originCell = origin.flatMap { map.nearestWalkable(to: map.cell(at: $0)) }
        let candidateFields = candidates.map { pathfinder.costs(from: $0.cell) }

        // A closure can cut a stop off entirely. Only the stops reachable from where the
        // walk starts are kept; the rest are reported so the visitor knows why they vanished.
        let reachCounts = candidates.indices.map { from in
            candidates.indices.filter { candidateFields[from][map.index(candidates[$0].cell)].isFinite }.count
        }
        let hub = candidates.indices.max { reachCounts[$0] < reachCounts[$1] } ?? 0
        let reachable: [Int] = candidates.indices.filter { index in
            if let originCell { return candidateFields[index][map.index(originCell)].isFinite }
            return candidateFields[hub][map.index(candidates[index].cell)].isFinite
        }
        let skippedSpaces = candidates.indices.filter { !reachable.contains($0) }.map { candidates[$0].request.spaceName }
        let stops = reachable.map { candidates[$0] }
        let fields = reachable.map { candidateFields[$0] }
        guard !stops.isEmpty else {
            return PlannedRoute(stops: [], legs: [], steps: [], origin: nil, closures: closureLines,
                                outsidePaths: [], skippedSpaces: skippedSpaces)
        }

        let costs = stops.indices.map { from in
            stops.indices.map { to in fields[from][map.index(stops[to].cell)] }
        }
        let startCosts: [Float] = stops.indices.map { index in
            guard let originCell else { return 0 }
            return fields[index][map.index(originCell)]
        }
        let order = StopOrderer.order(costs: costs, startCosts: startCosts, ranks: stops.map(\.request.rank))

        let narrator = RouteNarrator(map: map, doorName: doorName, outside: outside)
        var outsidePaths: [[CGPoint]] = []
        var plannedStops: [RouteStop] = []
        var legs: [[CGPoint]] = []
        var steps: [RouteStep] = []
        var current = originCell
        for (position, index) in order.enumerated() {
            let stop = stops[index]
            let center = CGPoint(x: stop.request.spaceRect.midX, y: stop.request.spaceRect.midY)
            plannedStops.append(RouteStop(
                id: stop.request.webCatalogID, circleID: stop.request.circleID, name: stop.request.name,
                spaceName: stop.request.spaceName, accessPoint: map.center(of: stop.cell), spaceCenter: center,
                colorRawValue: stop.request.colorRawValue
            ))
            guard let from = current else {
                legs.append([map.center(of: stop.cell)])
                steps.append(RouteStep(id: steps.count, stopIndex: position, blocks: 0, action: .begin,
                                       path: [map.center(of: stop.cell)]))
                current = stop.cell
                continue
            }
            let cells = pathfinder.path(from: from, to: stop.cell)
            let path = cells.isEmpty ? [stop.cell] : cells
            var leg: [CGPoint] = []
            for segment in RouteNarrator.segments(of: path) {
                if let last = leg.last, let first = segment.first {
                    let walk = outside(map.cell(at: last), first)
                    outsidePaths.append(walk)
                    leg += walk.dropFirst().dropLast()
                }
                leg += simplify(segment.map { map.center(of: $0) }, tolerance: CGFloat(WalkableMap.cellSize))
            }
            legs.append(leg)
            steps += narrator.steps(for: path, stopIndex: position, spaceCenter: center, firstID: steps.count)
            current = stop.cell
        }
        return PlannedRoute(stops: plannedStops, legs: legs, steps: steps, origin: originCell.map { map.center(of: $0) },
                            closures: closureLines, outsidePaths: outsidePaths, skippedSpaces: skippedSpaces)
    }

    /// Doors on the same wall open onto the same concourse, so a visitor can leave by one
    /// and come back in by another. The walk outside costs its length plus a fixed charge
    /// for the queue at each door, so routes only go outside when the way inside is shut
    /// or much longer.
    static let outsidePenalty: Float = 120.0

    private static func portals(between doors: [RouteDoor], in map: WalkableMap) -> [Int: [(to: Int, cost: Float)]] {
        var portals: [Int: [(to: Int, cost: Float)]] = [:]
        let size = CGFloat(WalkableMap.cellSize)
        for exit in doors where map.isWalkable(exit.cell) {
            for entry in doors where entry != exit && entry.edge == exit.edge && map.isWalkable(entry.cell) {
                let distance = hypot(exit.sign.midX - entry.sign.midX, exit.sign.midY - entry.sign.midY) / size
                portals[map.index(exit.cell), default: []].append(
                    (to: map.index(entry.cell), cost: Float(distance) + outsidePenalty)
                )
            }
        }
        return portals
    }

    private static func line(through cells: [GridPoint], in map: WalkableMap) -> (CGPoint, CGPoint)? {
        guard let first = cells.first else { return nil }
        let sameRow = cells.filter { $0.row == first.row }
        let sameColumn = cells.filter { $0.column == first.column }
        let band = sameRow.count >= sameColumn.count
            ? sameRow.sorted { $0.column < $1.column }
            : sameColumn.sorted { $0.row < $1.row }
        guard let start = band.first, let end = band.last else { return nil }
        return (map.center(of: start), map.center(of: end))
    }

    /// The aisle cell in front of a space. Every space has one side facing an aisle; the
    /// others touch its neighbours or the island's back row, so the side with the most
    /// room in front of it is the one buyers stand on.
    static func accessCell(for request: RouteStopRequest, in map: WalkableMap) -> GridPoint? {
        let size = WalkableMap.cellSize
        let top = Int(request.spaceRect.minY) / size
        let left = Int(request.spaceRect.minX) / size
        let bottom = (Int(request.spaceRect.maxY) - 1) / size
        let right = (Int(request.spaceRect.maxX) - 1) / size
        let sides: [(cells: [GridPoint], isSideways: Bool)] = [
            ((top...bottom).map { GridPoint(row: $0, column: left - 1) }, true),
            ((top...bottom).map { GridPoint(row: $0, column: right + 1) }, true),
            ((left...right).map { GridPoint(row: top - 1, column: $0) }, false),
            ((left...right).map { GridPoint(row: bottom + 1, column: $0) }, false)
        ]
        var best: (score: Float, cell: GridPoint)?
        for side in sides {
            let open = side.cells.filter { map.isWalkable($0) }
            guard !open.isEmpty else { continue }
            var score = Float(open.count) * 10.0
            score += open.reduce(0) { $0 + min(map.clearance[map.index($1)], 6.0) }
            if side.isSideways == request.opensSideways { score += 5.0 }
            if best == nil || score > best!.score {
                best = (score, open[open.count / 2])
            }
        }
        if let best { return best.cell }
        return map.nearestWalkable(to: GridPoint(row: (top + bottom) / 2, column: (left + right) / 2))
    }

    /// Douglas–Peucker, so a staircase along a diagonal wall draws as one straight line.
    static func simplify(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2, let first = points.first, let last = points.last else { return points }
        var farthest = 0
        var distance: CGFloat = 0
        let dx = last.x - first.x
        let dy = last.y - first.y
        let length = max((dx * dx + dy * dy).squareRoot(), 0.0001)
        for index in 1..<(points.count - 1) {
            let point = points[index]
            let offset = abs(dy * point.x - dx * point.y + last.x * first.y - last.y * first.x) / length
            if offset > distance {
                distance = offset
                farthest = index
            }
        }
        guard distance > tolerance else { return [first, last] }
        let head = simplify(Array(points[...farthest]), tolerance: tolerance)
        let tail = simplify(Array(points[farthest...]), tolerance: tolerance)
        return head.dropLast() + tail
    }
}
