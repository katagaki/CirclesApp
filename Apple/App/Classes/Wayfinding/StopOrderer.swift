/// Picks the order to visit stops in: an open path (the visitor does not come back) built
/// greedily, then untangled with 2-opt until no reversal makes it shorter.
nonisolated enum StopOrderer {

    /// Visits every stop of the lowest rank before any of the next, each group ordered on
    /// its own and entered from wherever the group before it finished.
    static func order(costs: [[Float]], startCosts: [Float], ranks: [Int]) -> [Int] {
        let groups = Set(ranks).sorted()
        guard groups.count > 1 else { return order(costs: costs, startCosts: startCosts) }
        var result: [Int] = []
        var entryCosts = startCosts
        for group in groups {
            let members = ranks.indices.filter { ranks[$0] == group }
            let local = order(
                costs: members.map { from in members.map { costs[from][$0] } },
                startCosts: members.map { entryCosts[$0] }
            ).map { members[$0] }
            result += local
            if let last = local.last {
                entryCosts = costs[last]
            }
        }
        return result
    }

    static func order(costs: [[Float]], startCosts: [Float]) -> [Int] {
        let count = costs.count
        guard count > 1 else { return Array(0..<count) }

        func total(_ order: [Int]) -> Float {
            var sum = startCosts[order[0]]
            for index in 0..<(order.count - 1) {
                sum += costs[order[index]][order[index + 1]]
            }
            return sum
        }

        let starts = startCosts.allSatisfy { $0 == 0 } ? Array(0..<count) : [
            startCosts.indices.min(by: { startCosts[$0] < startCosts[$1] }) ?? 0
        ]
        var best: [Int] = []
        var bestTotal = Float.infinity
        for start in starts {
            var order = [start]
            var remaining = Set(0..<count).subtracting([start])
            while let last = order.last, !remaining.isEmpty {
                let next = remaining.min(by: { costs[last][$0] < costs[last][$1] }) ?? last
                order.append(next)
                remaining.remove(next)
            }
            let length = total(order)
            if length < bestTotal {
                best = order
                bestTotal = length
            }
        }

        var improved = true
        while improved {
            improved = false
            for first in 0..<(count - 1) {
                for last in (first + 1)..<count {
                    var candidate = best
                    candidate[first...last].reverse()
                    let length = total(candidate)
                    if length + 0.001 < bestTotal {
                        best = candidate
                        bestTotal = length
                        improved = true
                    }
                }
            }
        }
        return best
    }
}
