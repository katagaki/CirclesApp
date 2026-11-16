package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Turns a path of grid cells into the kind of directions a person would give: how many
 * blocks to walk past, which way to turn, and which aisle or corridor that puts you in.
 */
class RouteNarrator(
    private val map: WalkableMap,
    private val doorName: (GridPoint) -> String = { "" },
    private val outside: (GridPoint, GridPoint) -> List<RoutePoint> = { _, _ -> emptyList() }
) {

    private data class Run(var start: Int, var end: Int, val direction: Pair<Int, Int>) {
        val length: Int get() = end - start
    }

    fun steps(path: List<GridPoint>, stopIndex: Int, spaceCenter: RoutePoint, firstID: Int): List<RouteStep> {
        val segments = segments(path)
        val steps = mutableListOf<RouteStep>()
        for ((position, segment) in segments.withIndex()) {
            val isLast = position == segments.size - 1
            val ending: RouteAction? = if (isLast) null else RouteAction.Exit(doorName(segment.last()))
            steps += insideSteps(segment, stopIndex, spaceCenter, firstID + steps.size, ending)
            if (!isLast) {
                val exit = segment.last()
                val entry = segments[position + 1].first()
                steps.add(
                    RouteStep(
                        id = firstID + steps.size, stopIndex = stopIndex, blocks = 0,
                        action = RouteAction.Enter(doorName(entry)), path = outside(exit, entry)
                    )
                )
            }
        }
        return steps
    }

    /**
     * Directions for one stretch indoors. It ends at the stop, or at a door when `ending`
     * says the walk carries on outside.
     */
    private fun insideSteps(
        path: List<GridPoint>, stopIndex: Int, spaceCenter: RoutePoint, firstID: Int, ending: RouteAction?
    ): List<RouteStep> {
        if (path.size <= 1) {
            return listOf(
                RouteStep(
                    id = firstID, stopIndex = stopIndex, blocks = 0,
                    action = ending ?: RouteAction.Arrive(RouteSide.AHEAD),
                    path = path.map { map.center(of = it) }
                )
            )
        }
        val runs = simplified(runs(path))
        val steps = mutableListOf<RouteStep>()
        for ((index, run) in runs.withIndex()) {
            val points = path.subList(run.start, run.end + 1).map { map.center(of = it) }
            val blocks = blocksPassed(path[run.start], path[run.end], run.direction)
            val action: RouteAction = if (index + 1 < runs.size) {
                val next = runs[index + 1]
                RouteAction.Turn(
                    turn(run.direction, next.direction),
                    passage(path[next.start], next.direction, next.length)
                )
            } else {
                ending ?: RouteAction.Arrive(side(spaceCenter, path[run.end], run.direction))
            }
            steps.add(RouteStep(id = firstID + index, stopIndex = stopIndex, blocks = blocks, action = action, path = points))
        }
        return steps
    }

    private fun runs(path: List<GridPoint>): MutableList<Run> {
        val runs = mutableListOf<Run>()
        for (index in 1 until path.size) {
            val direction = (path[index].row - path[index - 1].row) to (path[index].column - path[index - 1].column)
            val last = runs.lastOrNull()
            if (last != null && last.direction == direction) {
                last.end = index
            } else {
                runs.add(Run(index - 1, index, direction))
            }
        }
        return runs
    }

    /**
     * Sidesteps of a cell or two read as "turn left, turn right" while walking straight on,
     * so they are folded into the runs either side of them.
     */
    private fun simplified(runs: MutableList<Run>): List<Run> {
        var index = 1
        while (index < runs.size - 1) {
            if (runs[index].length <= 3 && runs[index - 1].direction == runs[index + 1].direction) {
                runs[index - 1].end = runs[index + 1].end
                runs.removeAt(index + 1)
                runs.removeAt(index)
            } else {
                index += 1
            }
        }
        if (runs.size > 1 && runs[0].length <= 4) {
            runs[1].start = runs[0].start
            runs.removeAt(0)
        }
        if (runs.size > 1 && runs[runs.size - 1].length <= 4) {
            runs[runs.size - 2].end = runs[runs.size - 1].end
            runs.removeAt(runs.size - 1)
        }
        return runs
    }

    /**
     * Islands beside the run whose middle it walks past. Islands facing each other across
     * the run overlap along it, so they count once, the way a person would count them.
     */
    private fun blocksPassed(start: GridPoint, end: GridPoint, direction: Pair<Int, Int>): Int {
        val reach = 7
        val isHorizontal = direction.first == 0
        val lower = if (isHorizontal) min(start.column, end.column) else min(start.row, end.row)
        val upper = if (isHorizontal) max(start.column, end.column) else max(start.row, end.row)
        val lane = if (isHorizontal) start.row else start.column
        val spans = mutableListOf<Pair<Int, Int>>()
        for (island in map.islands) {
            val across = if (isHorizontal) island.minRow to island.maxRow else island.minColumn to island.maxColumn
            val along = if (isHorizontal) island.minColumn to island.maxColumn else island.minRow to island.maxRow
            val gap = maxOf(across.first - lane, lane - across.second, 0)
            val middle = (along.first + along.second) / 2.0
            if (gap <= reach && lower.toDouble() < middle && middle < upper.toDouble()) spans.add(along)
        }
        spans.sortBy { it.first }
        var count = 0
        var covered = Int.MIN_VALUE
        for (span in spans) {
            if (span.first > covered) count += 1
            covered = max(covered, span.second)
        }
        return count
    }

    private fun passage(start: GridPoint, direction: Pair<Int, Int>, length: Int): RoutePassage {
        val reach = 8
        val sample = max(1, min(length, 12))
        val leftNames = HashMap<String, Int>()
        val rightNames = HashMap<String, Int>()
        val widths = mutableListOf<Float>()
        val leftward = -direction.second to direction.first
        val rightward = direction.second to -direction.first
        for (step in 0 until sample) {
            val cell = GridPoint(start.row + direction.first * step, start.column + direction.second * step)
            if (map.contains(cell)) widths.add(map.clearance[map.index(cell)])
            for ((offset, isLeft) in listOf(leftward to true, rightward to false)) {
                for (distance in 1 until reach) {
                    val probe = GridPoint(cell.row + offset.first * distance, cell.column + offset.second * distance)
                    if (!map.contains(probe)) break
                    val island = map.island(at = probe) ?: continue
                    val names = if (isLeft) leftNames else rightNames
                    names[island.name] = (names[island.name] ?: 0) + 1
                    break
                }
            }
        }
        widths.sort()
        val width = if (widths.isEmpty()) 0f else widths[widths.size / 2]
        val left = leftNames.maxByOrNull { it.value }?.key
        val right = rightNames.maxByOrNull { it.value }?.key
        if (width >= 6 || left == null || right == null) {
            val along = left ?: right
            return if (along != null) RoutePassage.CorridorAlong(along) else RoutePassage.Corridor
        }
        return if (left == right) RoutePassage.AisleThrough(left) else RoutePassage.AisleBetween(left, right)
    }

    /** Screen coordinates point down, so a positive cross product is a turn to the right. */
    private fun turn(heading: Pair<Int, Int>, next: Pair<Int, Int>): RouteTurn {
        val cross = heading.second * next.first - heading.first * next.second
        return when {
            cross > 0 -> RouteTurn.RIGHT
            cross < 0 -> RouteTurn.LEFT
            else -> RouteTurn.STRAIGHT
        }
    }

    private fun side(target: RoutePoint, cell: GridPoint, heading: Pair<Int, Int>): RouteSide {
        val here = map.center(of = cell)
        val toX = target.x - here.x
        val toY = target.y - here.y
        val cross = heading.second * toY - heading.first * toX
        val dot = heading.second * toX + heading.first * toY
        if (abs(cross) < abs(dot) * 0.5) return RouteSide.AHEAD
        return if (cross > 0) RouteSide.RIGHT else RouteSide.LEFT
    }

    companion object {
        /**
         * A path split wherever it leaves the hall through one door and comes back in through
         * another, which shows up as two neighbouring cells that are not next to each other.
         */
        fun segments(path: List<GridPoint>): List<List<GridPoint>> {
            val segments = mutableListOf(mutableListOf<GridPoint>())
            for (cell in path) {
                val last = segments.last().lastOrNull()
                if (last != null && abs(last.row - cell.row) + abs(last.column - cell.column) > 1) {
                    segments.add(mutableListOf())
                }
                segments.last().add(cell)
            }
            return segments.filter { it.isNotEmpty() }
        }
    }
}
