package com.tsubuzaki.circlesgo.wayfinding

/**
 * Shortest paths on the walkable grid. Each step costs more the closer it runs to a
 * table, which keeps routes in the middle of an aisle instead of brushing the tables.
 */
class Pathfinder(val map: WalkableMap) {

    class Portal(val to: Int, val cost: Float)

    var portals: Map<Int, List<Portal>> = emptyMap()

    /**
     * Extra cost for cells earlier legs of the route already walked, so a later leg takes
     * a parallel aisle when one is about as short instead of retracing the same stretch.
     */
    var wear: FloatArray = FloatArray(0)

    fun costs(start: GridPoint): FloatArray {
        val cost = FloatArray(map.walkable.size) { Float.POSITIVE_INFINITY }
        if (!map.isWalkable(start)) return cost
        val heap = MinHeap()
        cost[map.index(start)] = 0f
        heap.push(0f, map.index(start))
        while (!heap.isEmpty()) {
            val current = heap.peekKey()
            val index = heap.pop()
            if (current > cost[index]) continue
            val row = index / map.columns
            val column = index % map.columns
            for ((dy, dx) in DIRECTIONS) {
                val next = GridPoint(row + dy, column + dx)
                if (!map.isWalkable(next)) continue
                val nextIndex = map.index(next)
                val total = current + map.stepCost[nextIndex]
                if (total < cost[nextIndex]) {
                    cost[nextIndex] = total
                    heap.push(total, nextIndex)
                }
            }
            portals[index]?.forEach { portal ->
                val total = current + portal.cost
                if (total < cost[portal.to]) {
                    cost[portal.to] = total
                    heap.push(total, portal.to)
                }
            }
        }
        return cost
    }

    /**
     * The path between two cells, searched over cell and heading so that every turn costs
     * extra. Without it, ties are broken into staircases that would read as a dozen turns.
     */
    fun path(start: GridPoint, goal: GridPoint): List<GridPoint> {
        if (!map.isWalkable(start) || !map.isWalkable(goal)) return emptyList()
        if (start == goal) return listOf(start)
        val stateCount = map.walkable.size * 4
        val cost = FloatArray(stateCount) { Float.POSITIVE_INFINITY }
        val previous = IntArray(stateCount) { -1 }
        val heap = MinHeap()
        val startIndex = map.index(start)
        for (heading in 0 until 4) {
            cost[startIndex * 4 + heading] = 0f
            heap.push(0f, startIndex * 4 + heading)
        }
        val goalIndex = map.index(goal)
        var reached = -1
        while (!heap.isEmpty()) {
            val current = heap.peekKey()
            val state = heap.pop()
            if (current > cost[state]) continue
            val index = state / 4
            val heading = state % 4
            if (index == goalIndex) {
                reached = state
                break
            }
            val row = index / map.columns
            val column = index % map.columns
            for ((nextHeading, direction) in DIRECTIONS.withIndex()) {
                val next = GridPoint(row + direction.first, column + direction.second)
                if (!map.isWalkable(next)) continue
                val nextIndex = map.index(next)
                val turn = when {
                    index == startIndex || nextHeading == heading -> 0f
                    (nextHeading + 2) % 4 == heading -> TURN_PENALTY * 3
                    else -> TURN_PENALTY
                }
                val worn = if (wear.isEmpty()) 0f else wear[nextIndex]
                val total = current + map.stepCost[nextIndex] + turn + worn
                val nextState = nextIndex * 4 + nextHeading
                if (total < cost[nextState]) {
                    cost[nextState] = total
                    previous[nextState] = state
                    heap.push(total, nextState)
                }
            }
            portals[index]?.forEach { portal ->
                val total = current + portal.cost
                for (arrival in 0 until 4) {
                    val nextState = portal.to * 4 + arrival
                    if (total < cost[nextState]) {
                        cost[nextState] = total
                        previous[nextState] = state
                        heap.push(total, nextState)
                    }
                }
            }
        }
        if (reached < 0) return emptyList()
        val cells = mutableListOf<GridPoint>()
        var state = reached
        while (state >= 0) {
            val index = state / 4
            cells.add(GridPoint(index / map.columns, index % map.columns))
            state = previous[state]
        }
        return cells.reversed()
    }

    companion object {
        const val TURN_PENALTY: Float = 6.0f
        private val DIRECTIONS = listOf(0 to 1, 1 to 0, 0 to -1, -1 to 0)
    }
}

class MinHeap {

    private var keys = FloatArray(256)
    private var values = IntArray(256)
    private var count = 0

    fun isEmpty(): Boolean = count == 0

    fun peekKey(): Float = keys[0]

    fun push(key: Float, value: Int) {
        if (count == keys.size) {
            keys = keys.copyOf(count * 2)
            values = values.copyOf(count * 2)
        }
        keys[count] = key
        values[count] = value
        var child = count
        count++
        while (child > 0) {
            val parent = (child - 1) / 2
            if (keys[child] >= keys[parent]) break
            swap(child, parent)
            child = parent
        }
    }

    fun pop(): Int {
        val firstValue = values[0]
        count--
        if (count > 0) {
            keys[0] = keys[count]
            values[0] = values[count]
            var parent = 0
            while (true) {
                val left = parent * 2 + 1
                val right = left + 1
                var smallest = parent
                if (left < count && keys[left] < keys[smallest]) smallest = left
                if (right < count && keys[right] < keys[smallest]) smallest = right
                if (smallest == parent) break
                swap(parent, smallest)
                parent = smallest
            }
        }
        return firstValue
    }

    private fun swap(first: Int, second: Int) {
        val key = keys[first]
        keys[first] = keys[second]
        keys[second] = key
        val value = values[first]
        values[first] = values[second]
        values[second] = value
    }
}
