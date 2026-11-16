package com.tsubuzaki.circlesgo.wayfinding

/**
 * Picks the order to visit stops in: an open path (the visitor does not come back) built
 * greedily, then untangled with 2-opt until no reversal makes it shorter.
 */
object StopOrderer {

    /**
     * Visits every stop of the lowest rank before any of the next, each group ordered on
     * its own and entered from wherever the group before it finished.
     */
    fun order(costs: List<FloatArray>, startCosts: FloatArray, ranks: List<Int>): List<Int> {
        val groups = ranks.toSet().sorted()
        if (groups.size <= 1) return order(costs, startCosts)
        val result = mutableListOf<Int>()
        var entryCosts = startCosts
        for (group in groups) {
            val members = ranks.indices.filter { ranks[it] == group }
            val local = order(
                members.map { from -> FloatArray(members.size) { costs[from][members[it]] } },
                FloatArray(members.size) { entryCosts[members[it]] }
            ).map { members[it] }
            result += local
            local.lastOrNull()?.let { entryCosts = costs[it] }
        }
        return result
    }

    fun length(order: List<Int>, costs: List<FloatArray>, startCosts: FloatArray): Float {
        val first = order.firstOrNull() ?: return 0f
        var sum = startCosts[first]
        for (index in 0 until order.size - 1) {
            sum += costs[order[index]][order[index + 1]]
        }
        return sum
    }

    fun order(costs: List<FloatArray>, startCosts: FloatArray): List<Int> {
        val count = costs.size
        if (count <= 1) return (0 until count).toList()

        val starts = if (startCosts.all { it == 0f }) {
            (0 until count).toList()
        } else {
            listOf(startCosts.indices.minByOrNull { startCosts[it] } ?: 0)
        }
        var best: List<Int> = emptyList()
        var bestTotal = Float.POSITIVE_INFINITY
        for (start in starts) {
            val order = mutableListOf(start)
            val remaining = (0 until count).toMutableSet().apply { remove(start) }
            while (remaining.isNotEmpty()) {
                val last = order.last()
                val next = remaining.sorted().minByOrNull { costs[last][it] } ?: last
                order.add(next)
                remaining.remove(next)
            }
            val total = length(order, costs, startCosts)
            if (total < bestTotal) {
                best = order
                bestTotal = total
            }
        }
        if (best.isEmpty()) best = starts.first().let { start -> listOf(start) + (0 until count).filter { it != start } }

        var improved = true
        while (improved) {
            improved = false
            for (first in 0 until count - 1) {
                for (last in (first + 1) until count) {
                    val candidate = best.toMutableList()
                    candidate.subList(first, last + 1).reverse()
                    val total = length(candidate, costs, startCosts)
                    if (total + 0.001f < bestTotal) {
                        best = candidate
                        bestTotal = total
                        improved = true
                    }
                }
            }
        }
        return best
    }
}
