/// Shortest paths on the walkable grid. Each step costs more the closer it runs to a
/// table, which keeps routes in the middle of an aisle instead of brushing the tables.
nonisolated struct Pathfinder {

    static let turnPenalty: Float = 6.0
    private static let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]

    let map: WalkableMap
    var portals: [Int: [(to: Int, cost: Float)]] = [:]

    func costs(from start: GridPoint) -> [Float] {
        var cost = [Float](repeating: .infinity, count: map.walkable.count)
        guard map.isWalkable(start) else { return cost }
        var heap = MinHeap()
        cost[map.index(start)] = 0
        heap.push(0, map.index(start))
        while let (current, index) = heap.pop() {
            guard current <= cost[index] else { continue }
            let row = index / map.columns
            let column = index % map.columns
            for (dy, dx) in Self.directions {
                let next = GridPoint(row: row + dy, column: column + dx)
                guard map.isWalkable(next) else { continue }
                let nextIndex = map.index(next)
                let total = current + map.stepCost[nextIndex]
                if total < cost[nextIndex] {
                    cost[nextIndex] = total
                    heap.push(total, nextIndex)
                }
            }
            for portal in portals[index] ?? [] {
                let total = current + portal.cost
                if total < cost[portal.to] {
                    cost[portal.to] = total
                    heap.push(total, portal.to)
                }
            }
        }
        return cost
    }

    /// The path between two cells, searched over cell and heading so that every turn costs
    /// extra. Without it, ties are broken into staircases that would read as a dozen turns.
    func path(from start: GridPoint, to goal: GridPoint) -> [GridPoint] {
        guard map.isWalkable(start), map.isWalkable(goal) else { return [] }
        if start == goal { return [start] }
        let stateCount = map.walkable.count * 4
        var cost = [Float](repeating: .infinity, count: stateCount)
        var previous = [Int32](repeating: -1, count: stateCount)
        var heap = MinHeap()
        let startIndex = map.index(start)
        for heading in 0..<4 {
            cost[startIndex * 4 + heading] = 0
            heap.push(0, startIndex * 4 + heading)
        }
        let goalIndex = map.index(goal)
        var reached: Int?
        while let (current, state) = heap.pop() {
            guard current <= cost[state] else { continue }
            let index = state / 4
            let heading = state % 4
            if index == goalIndex {
                reached = state
                break
            }
            let row = index / map.columns
            let column = index % map.columns
            for (nextHeading, (dy, dx)) in Self.directions.enumerated() {
                let next = GridPoint(row: row + dy, column: column + dx)
                guard map.isWalkable(next) else { continue }
                let nextIndex = map.index(next)
                let turn: Float
                if index == startIndex || nextHeading == heading {
                    turn = 0
                } else if (nextHeading + 2) % 4 == heading {
                    turn = Self.turnPenalty * 3
                } else {
                    turn = Self.turnPenalty
                }
                let total = current + map.stepCost[nextIndex] + turn
                let nextState = nextIndex * 4 + nextHeading
                if total < cost[nextState] {
                    cost[nextState] = total
                    previous[nextState] = Int32(state)
                    heap.push(total, nextState)
                }
            }
            for portal in portals[index] ?? [] {
                let total = current + portal.cost
                for arrival in 0..<4 {
                    let nextState = portal.to * 4 + arrival
                    if total < cost[nextState] {
                        cost[nextState] = total
                        previous[nextState] = Int32(state)
                        heap.push(total, nextState)
                    }
                }
            }
        }
        guard var state = reached else { return [] }
        var cells: [GridPoint] = []
        while state >= 0 {
            let index = state / 4
            cells.append(GridPoint(row: index / map.columns, column: index % map.columns))
            state = Int(previous[state])
        }
        return cells.reversed()
    }
}

nonisolated struct MinHeap {

    private var keys: [Float] = []
    private var values: [Int] = []

    mutating func push(_ key: Float, _ value: Int) {
        keys.append(key)
        values.append(value)
        var child = keys.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard keys[child] < keys[parent] else { break }
            keys.swapAt(child, parent)
            values.swapAt(child, parent)
            child = parent
        }
    }

    mutating func pop() -> (Float, Int)? {
        guard let firstKey = keys.first, let firstValue = values.first else { return nil }
        let lastKey = keys.removeLast()
        let lastValue = values.removeLast()
        if !keys.isEmpty {
            keys[0] = lastKey
            values[0] = lastValue
            var parent = 0
            while true {
                let left = parent * 2 + 1
                let right = left + 1
                var smallest = parent
                if left < keys.count && keys[left] < keys[smallest] { smallest = left }
                if right < keys.count && keys[right] < keys[smallest] { smallest = right }
                guard smallest != parent else { break }
                keys.swapAt(parent, smallest)
                values.swapAt(parent, smallest)
                parent = smallest
            }
        }
        return (firstKey, firstValue)
    }
}
