package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Turns a walk over grid cells into the line drawn on the map. Long runs stay straight
 * along the aisle, and the short steps between them become one angled stroke, so a
 * sidestep of a cell reads as a slight bend rather than a lean across the whole aisle.
 */
object RouteStraightener {

    /** Runs this long or shorter are sidesteps, not stretches of aisle. */
    val jogLength: Double = WalkableMap.CELL_SIZE * 2.0

    /**
     * `arrivalAxis` is the way the aisle runs in front of the stop the walk ends at. When
     * the walk comes down that aisle and only steps aside to reach the stop, the end moves
     * onto the line instead, so the line runs through the stop's badge rather than past it.
     */
    fun straighten(points: List<RoutePoint>, arrivalAxis: RoutePoint? = null): List<RoutePoint> {
        val walk = corners(points)
        if (walk.size <= 2) return walk
        val isLong = walk.zipWithNext { first, second -> distance(first, second) > jogLength }
        if (!isLong.contains(true)) return listOf(walk[0], walk[walk.size - 1])
        val result = mutableListOf(walk[0])
        var index = 0
        while (index < isLong.size) {
            if (isLong[index]) {
                result.add(walk[index + 1])
                index += 1
                continue
            }
            var end = index
            while (end < isLong.size && !isLong[end]) end += 1
            result.removeAt(result.size - 1)
            result += bend(walk, index, end, arrivalAxis)
            index = end
        }
        return corners(result)
    }

    /**
     * Replaces the short runs between corners `start` and `end` with one stroke, pulled
     * back into the long runs on either side so it leaves them at 45 degrees.
     */
    private fun bend(corners: List<RoutePoint>, start: Int, end: Int, arrivalAxis: RoutePoint?): List<RoutePoint> {
        val from = corners[start]
        val to = corners[end]
        val before = if (start > 0) unit(corners[start - 1], from) else null
        val after = if (end < corners.size - 1) unit(to, corners[end + 1]) else null
        if (before != null && after != null && abs(dot(before, after)) < 0.1) return listOf(from, to)
        if (before != null && after != null && dot(before, after) < 0.9) return corners.subList(start, end + 1).toList()
        val direction = before ?: after ?: return listOf(from, to)
        val offset = RoutePoint(to.x - from.x, to.y - from.y)
        val along = dot(offset, direction)
        val across = hypot(offset.x - along * direction.x, offset.y - along * direction.y)
        if (after == null && before != null && arrivalAxis != null &&
            abs(dot(before, arrivalAxis)) > 0.9 && across <= jogLength
        ) {
            return listOf(RoutePoint(from.x + direction.x * along, from.y + direction.y * along))
        }
        val extra = max(across - along, 0.0)
        val backLength = if (start > 0) distance(corners[start - 1], from) / 2.0 else 0.0
        val aheadLength = if (end < corners.size - 1) distance(to, corners[end + 1]) / 2.0 else 0.0
        val share = if (before != null && after != null) extra / 2.0 else extra
        val back = if (before == null) 0.0 else min(share, backLength)
        val ahead = if (after == null) 0.0 else min(share, aheadLength)
        return listOf(
            RoutePoint(from.x - direction.x * back, from.y - direction.y * back),
            RoutePoint(to.x + direction.x * ahead, to.y + direction.y * ahead)
        )
    }

    /** The points where the walk changes direction, plus its two ends. */
    fun corners(points: List<RoutePoint>): List<RoutePoint> {
        val result = mutableListOf<RoutePoint>()
        for (point in points) {
            val last = result.lastOrNull()
            if (last != null && distance(last, point) < 0.01) continue
            if (result.size >= 2) {
                val first = unit(result[result.size - 2], result[result.size - 1])
                val second = unit(result[result.size - 1], point)
                if (abs(first.x * second.y - first.y * second.x) < 0.01 && dot(first, second) > 0) {
                    result[result.size - 1] = point
                    continue
                }
            }
            result.add(point)
        }
        return result
    }

    private fun distance(first: RoutePoint, second: RoutePoint): Double =
        hypot(second.x - first.x, second.y - first.y)

    private fun unit(from: RoutePoint, to: RoutePoint): RoutePoint {
        val length = max(distance(from, to), 0.0001)
        return RoutePoint((to.x - from.x) / length, (to.y - from.y) / length)
    }

    private fun dot(first: RoutePoint, second: RoutePoint): Double = first.x * second.x + first.y * second.y
}
