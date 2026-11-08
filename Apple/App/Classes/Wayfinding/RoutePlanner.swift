import CoreGraphics

nonisolated enum RoutePlanner {

    static func plan(map: WalkableMap, stops requests: [RouteStopRequest], origin: CGPoint?) -> PlannedRoute? {
        let pathfinder = Pathfinder(map: map)
        var stops: [(request: RouteStopRequest, cell: GridPoint)] = []
        for request in requests {
            if let cell = accessCell(for: request, in: map) {
                stops.append((request, cell))
            }
        }
        guard !stops.isEmpty else { return nil }

        let originCell = origin.flatMap { map.nearestWalkable(to: map.cell(at: $0)) }
        let fields = stops.map { pathfinder.costs(from: $0.cell) }
        let costs = stops.indices.map { from in
            stops.indices.map { to in fields[from][map.index(stops[to].cell)] }
        }
        let startCosts: [Float] = stops.indices.map { index in
            guard let originCell else { return 0 }
            return fields[index][map.index(originCell)]
        }
        let order = StopOrderer.order(costs: costs, startCosts: startCosts)

        let narrator = RouteNarrator(map: map)
        var plannedStops: [RouteStop] = []
        var legs: [[CGPoint]] = []
        var steps: [RouteStep] = []
        var current = originCell
        for (position, index) in order.enumerated() {
            let stop = stops[index]
            let center = CGPoint(x: stop.request.spaceRect.midX, y: stop.request.spaceRect.midY)
            plannedStops.append(RouteStop(
                id: stop.request.webCatalogID, circleID: stop.request.circleID, name: stop.request.name,
                spaceName: stop.request.spaceName, accessPoint: map.center(of: stop.cell), spaceCenter: center
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
            legs.append(simplify(path.map { map.center(of: $0) }, tolerance: CGFloat(WalkableMap.cellSize)))
            steps += narrator.steps(for: path, stopIndex: position, spaceCenter: center, firstID: steps.count)
            current = stop.cell
        }
        return PlannedRoute(stops: plannedStops, legs: legs, steps: steps, origin: originCell.map { map.center(of: $0) })
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
