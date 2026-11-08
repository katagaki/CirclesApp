/// Picks the order to visit stops in: an open path (the visitor does not come back) built
/// greedily, then untangled with 2-opt until no reversal makes it shorter.
nonisolated enum StopOrderer {

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
