import CoreGraphics

/// Turns a path of grid cells into the kind of directions a person would give: how many
/// blocks to walk past, which way to turn, and which aisle or corridor that puts you in.
nonisolated struct RouteNarrator {

    private struct Run {
        var start: Int
        var end: Int
        var direction: (Int, Int)
        var length: Int { end - start }
    }

    let map: WalkableMap

    func steps(
        for path: [GridPoint], stopIndex: Int, spaceCenter: CGPoint, firstID: Int
    ) -> [RouteStep] {
        guard path.count > 1 else {
            return [RouteStep(id: firstID, stopIndex: stopIndex, blocks: 0, action: .arrive(.ahead),
                              path: path.map { map.center(of: $0) })]
        }
        let runs = simplified(runs(in: path))
        var steps: [RouteStep] = []
        for (index, run) in runs.enumerated() {
            let points = Array(path[run.start...run.end]).map { map.center(of: $0) }
            let blocks = blocksPassed(from: path[run.start], to: path[run.end], along: run.direction)
            let action: RouteAction
            if index + 1 < runs.count {
                let next = runs[index + 1]
                action = .turn(turn(from: run.direction, to: next.direction),
                               into: passage(from: path[next.start], along: next.direction, length: next.length))
            } else {
                action = .arrive(side(of: spaceCenter, from: path[run.end], heading: run.direction))
            }
            steps.append(RouteStep(id: firstID + index, stopIndex: stopIndex, blocks: blocks,
                                   action: action, path: points))
        }
        return steps
    }

    private func runs(in path: [GridPoint]) -> [Run] {
        var runs: [Run] = []
        for index in 1..<path.count {
            let direction = (path[index].row - path[index - 1].row, path[index].column - path[index - 1].column)
            if var last = runs.last, last.direction == direction {
                last.end = index
                runs[runs.count - 1] = last
            } else {
                runs.append(Run(start: index - 1, end: index, direction: direction))
            }
        }
        return runs
    }

    /// Sidesteps of a cell or two read as "turn left, turn right" while walking straight on,
    /// so they are folded into the runs either side of them.
    private func simplified(_ input: [Run]) -> [Run] {
        var runs = input
        var index = 1
        while index < runs.count - 1 {
            if runs[index].length <= 3 && runs[index - 1].direction == runs[index + 1].direction {
                runs[index - 1].end = runs[index + 1].end
                runs.removeSubrange(index...(index + 1))
            } else {
                index += 1
            }
        }
        if runs.count > 1 && runs[0].length <= 4 {
            runs[1].start = runs[0].start
            runs.removeFirst()
        }
        if runs.count > 1 && runs[runs.count - 1].length <= 4 {
            runs[runs.count - 2].end = runs[runs.count - 1].end
            runs.removeLast()
        }
        return runs
    }

    /// Islands beside the run whose middle it walks past. Islands facing each other across
    /// the run overlap along it, so they count once, the way a person would count them.
    private func blocksPassed(from start: GridPoint, to end: GridPoint, along direction: (Int, Int)) -> Int {
        let reach = 7
        let isHorizontal = direction.0 == 0
        let lower = isHorizontal ? min(start.column, end.column) : min(start.row, end.row)
        let upper = isHorizontal ? max(start.column, end.column) : max(start.row, end.row)
        let lane = isHorizontal ? start.row : start.column
        var spans: [(Int, Int)] = []
        for island in map.islands {
            let across = isHorizontal ? (island.minRow, island.maxRow) : (island.minColumn, island.maxColumn)
            let along = isHorizontal ? (island.minColumn, island.maxColumn) : (island.minRow, island.maxRow)
            let gap = max(across.0 - lane, lane - across.1, 0)
            let middle = Double(along.0 + along.1) / 2.0
            if gap <= reach && Double(lower) < middle && middle < Double(upper) {
                spans.append(along)
            }
        }
        spans.sort { $0.0 < $1.0 }
        var count = 0
        var covered = Int.min
        for span in spans {
            if span.0 > covered { count += 1 }
            covered = max(covered, span.1)
        }
        return count
    }

    private func passage(from start: GridPoint, along direction: (Int, Int), length: Int) -> RoutePassage {
        let reach = 8
        let sample = max(1, min(length, 12))
        var leftNames: [String: Int] = [:]
        var rightNames: [String: Int] = [:]
        var widths: [Float] = []
        let leftward = (-direction.1, direction.0)
        let rightward = (direction.1, -direction.0)
        for step in 0..<sample {
            let cell = GridPoint(row: start.row + direction.0 * step, column: start.column + direction.1 * step)
            if map.contains(cell) { widths.append(map.clearance[map.index(cell)]) }
            for (offset, isLeft) in [(leftward, true), (rightward, false)] {
                for distance in 1..<reach {
                    let probe = GridPoint(row: cell.row + offset.0 * distance, column: cell.column + offset.1 * distance)
                    guard map.contains(probe) else { break }
                    if let island = map.island(at: probe) {
                        if isLeft {
                            leftNames[island.name, default: 0] += 1
                        } else {
                            rightNames[island.name, default: 0] += 1
                        }
                        break
                    }
                }
            }
        }
        widths.sort()
        let width = widths.isEmpty ? 0 : widths[widths.count / 2]
        let left = leftNames.max(by: { $0.value < $1.value })?.key
        let right = rightNames.max(by: { $0.value < $1.value })?.key
        if width >= 6 || left == nil || right == nil {
            if let along = left ?? right {
                return .corridorAlong(along)
            }
            return .corridor
        }
        guard let left, let right else { return .corridor }
        return left == right ? .aisleThrough(left) : .aisleBetween(left, right)
    }

    /// Screen coordinates point down, so a positive cross product is a turn to the right.
    private func turn(from heading: (Int, Int), to next: (Int, Int)) -> RouteTurn {
        let cross = heading.1 * next.0 - heading.0 * next.1
        if cross > 0 { return .right }
        if cross < 0 { return .left }
        return .straight
    }

    private func side(of target: CGPoint, from cell: GridPoint, heading: (Int, Int)) -> RouteSide {
        let here = map.center(of: cell)
        let toTarget = (x: target.x - here.x, y: target.y - here.y)
        let cross = CGFloat(heading.1) * toTarget.y - CGFloat(heading.0) * toTarget.x
        let dot = CGFloat(heading.1) * toTarget.x + CGFloat(heading.0) * toTarget.y
        if abs(cross) < abs(dot) * 0.5 { return .ahead }
        return cross > 0 ? .right : .left
    }
}
