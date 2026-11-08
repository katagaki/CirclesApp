import CoreGraphics

extension WalkableMap {

    /// The cells that seal off the aisle at a point: a band two cells thick laid across the
    /// aisle from table to table. The aisle runs whichever way the open space through the
    /// point is longer, so the band goes across the shorter way.
    func closureCells(at point: CGPoint, across given: GridPoint? = nil) -> [GridPoint] {
        guard let center = nearestWalkable(to: cell(at: point)) else { return [] }
        let across: (Int, Int)
        if let given {
            across = (given.row, given.column)
        } else {
            let horizontal = openRun(from: center, along: (0, 1))
            let vertical = openRun(from: center, along: (1, 0))
            across = horizontal >= vertical ? (1, 0) : (0, 1)
        }
        let along: (Int, Int) = (across.1, across.0)
        var cells: [GridPoint] = []
        for thickness in 0..<2 {
            let base = GridPoint(row: center.row + along.0 * thickness, column: center.column + along.1 * thickness)
            guard isWalkable(base) else { continue }
            cells.append(base)
            for sign in [-1, 1] {
                for distance in 1...20 {
                    let next = GridPoint(row: base.row + across.0 * distance * sign,
                                         column: base.column + across.1 * distance * sign)
                    guard isWalkable(next) else { break }
                    cells.append(next)
                }
            }
        }
        return cells
    }

    /// Where along a stretch of path to seal it: the narrowest point, so the closure cuts
    /// one aisle rather than running down a crossing corridor. The band lies across the
    /// direction of travel there.
    func narrowestCrossing(along points: [CGPoint]) -> (point: CGPoint, across: GridPoint)? {
        let cells = points.map { cell(at: $0) }
        guard cells.count >= 2 else { return nil }
        var best: (width: Int, index: Int, across: GridPoint)?
        let firstCandidate = cells.count > 4 ? 2 : 1
        for index in firstCandidate..<cells.count {
            let row = cells[index].row - cells[index - 1].row
            let column = cells[index].column - cells[index - 1].column
            let across = GridPoint(row: abs(column), column: abs(row))
            let width = openRun(from: cells[index], along: (across.row, across.column))
            if best == nil || width < best!.width {
                best = (width, index, across)
            }
        }
        guard let best else { return nil }
        return (center(of: cells[best.index]), best.across)
    }

    func blocking(_ cells: [GridPoint]) -> WalkableMap {
        var walkable = self.walkable
        for cell in cells where contains(cell) {
            walkable[index(cell)] = false
        }
        return WalkableMap(
            rows: rows, columns: columns, walkable: walkable, clearance: clearance,
            stepCost: stepCost, islandLabels: islandLabels, islands: islands
        )
    }

    private func openRun(from start: GridPoint, along direction: (Int, Int)) -> Int {
        var length = 1
        for sign in [-1, 1] {
            var distance = 1
            while distance < 60 {
                let next = GridPoint(row: start.row + direction.0 * distance * sign,
                                     column: start.column + direction.1 * distance * sign)
                guard isWalkable(next) else { break }
                length += 1
                distance += 1
            }
        }
        return length
    }
}
