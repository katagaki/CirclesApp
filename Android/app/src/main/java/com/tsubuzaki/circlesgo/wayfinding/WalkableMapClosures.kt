package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.abs

/**
 * The cells that seal off the aisle at a point: a band two cells thick laid across the
 * aisle from table to table. The aisle runs whichever way the open space through the
 * point is longer, so the band goes across the shorter way.
 */
fun WalkableMap.closureCells(point: RoutePoint, given: GridPoint? = null): List<GridPoint> {
    val center = nearestWalkable(cell(at = point)) ?: return emptyList()
    val across: Pair<Int, Int> = if (given != null) {
        given.row to given.column
    } else {
        val horizontal = openRun(center, 0 to 1)
        val vertical = openRun(center, 1 to 0)
        if (horizontal >= vertical) 1 to 0 else 0 to 1
    }
    val along = across.second to across.first
    val cells = mutableListOf<GridPoint>()
    for (thickness in 0 until 2) {
        val base = GridPoint(center.row + along.first * thickness, center.column + along.second * thickness)
        if (!isWalkable(base)) continue
        cells.add(base)
        for (sign in listOf(-1, 1)) {
            for (distance in 1..20) {
                val next = GridPoint(
                    base.row + across.first * distance * sign,
                    base.column + across.second * distance * sign
                )
                if (!isWalkable(next)) break
                cells.add(next)
            }
        }
    }
    return cells
}

/**
 * Where along a stretch of path to seal it: the narrowest point, so the closure cuts
 * one aisle rather than running down a crossing corridor. The band lies across the
 * direction of travel there.
 */
fun WalkableMap.narrowestCrossing(points: List<RoutePoint>): Pair<RoutePoint, GridPoint>? {
    val cells = points.map { cell(at = it) }
    if (cells.size < 2) return null
    var bestWidth = Int.MAX_VALUE
    var bestIndex = -1
    var bestAcross: GridPoint? = null
    val firstCandidate = if (cells.size > 4) 2 else 1
    for (index in firstCandidate until cells.size) {
        val row = cells[index].row - cells[index - 1].row
        val column = cells[index].column - cells[index - 1].column
        val across = GridPoint(abs(column), abs(row))
        val width = openRun(cells[index], across.row to across.column)
        if (bestIndex < 0 || width < bestWidth) {
            bestWidth = width
            bestIndex = index
            bestAcross = across
        }
    }
    val across = bestAcross ?: return null
    return center(of = cells[bestIndex]) to across
}

fun WalkableMap.blocking(cells: List<GridPoint>): WalkableMap {
    val walkable = this.walkable.copyOf()
    for (cell in cells) if (contains(cell)) walkable[index(cell)] = false
    return copy(walkable = walkable)
}

/** Every walkable cell within a cell of a vertical line, so nothing crosses it. */
fun WalkableMap.boundaryCells(x: Double): List<GridPoint> {
    val column = x.toInt() / WalkableMap.CELL_SIZE
    val cells = mutableListOf<GridPoint>()
    for (row in 0 until rows) {
        for (offset in -1..1) {
            val cell = GridPoint(row, column + offset)
            if (isWalkable(cell)) cells.add(cell)
        }
    }
    return cells
}

private fun WalkableMap.openRun(start: GridPoint, direction: Pair<Int, Int>): Int {
    var length = 1
    for (sign in listOf(-1, 1)) {
        var distance = 1
        while (distance < 60) {
            val next = GridPoint(
                start.row + direction.first * distance * sign,
                start.column + direction.second * distance * sign
            )
            if (!isWalkable(next)) break
            length += 1
            distance += 1
        }
    }
    return length
}
