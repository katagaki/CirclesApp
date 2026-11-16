package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.min

object RoutePlanner {

    /**
     * Doors on the same wall open onto the same concourse, so a visitor can leave by one
     * and come back in by another. The walk outside costs its length plus a fixed charge
     * for the queue at each door, so routes only go outside when the way inside is shut
     * or much longer.
     */
    const val OUTSIDE_PENALTY: Float = 120.0f

    /**
     * What walking a cell again costs on top of its usual step. A cell in the middle of an
     * aisle costs about 2, so retracing a stretch costs nearly twice as much as a fresh one.
     */
    const val WEAR_PENALTY: Float = 1.5f

    private class Candidate(
        val request: RouteStopRequest,
        val cell: GridPoint,
        val point: RoutePoint,
        val axis: RoutePoint?
    )

    fun plan(
        baseMap: WalkableMap,
        requests: List<RouteStopRequest>,
        origin: RoutePoint?,
        closures: List<RouteClosure> = emptyList(),
        halls: List<RouteHall> = emptyList()
    ): PlannedRoute? {
        val (blockedCells, closureLines) = seal(closures, baseMap)
        val map = baseMap.blocking(blockedCells)
        val pathfinder = Pathfinder(map)
        val boundaries = halls.zipWithNext { left, right -> (left.rect.maxX + right.rect.minX) / 2.0 }
        val doors = map.doors.filter { door ->
            !door.isSign || boundaries.none { abs(it - door.sign.midX) < 160.0 }
        }
        pathfinder.portals = portals(doors, map)
        val doorsByCell = HashMap<Int, RouteDoor>()
        for (door in doors) doorsByCell.putIfAbsent(map.index(door.cell), door)
        val doorName: (GridPoint) -> String = { cell ->
            val door = doorsByCell[map.index(cell)]
            if (door == null) {
                ""
            } else {
                halls.firstOrNull { it.rect.minX <= door.sign.midX && door.sign.midX < it.rect.maxX }?.name ?: ""
            }
        }
        val outside: (GridPoint, GridPoint) -> List<RoutePoint> = { from, to ->
            val exit = doorsByCell[map.index(from)]
            val entry = doorsByCell[map.index(to)]
            if (exit == null || entry == null) {
                listOf(map.center(of = from), map.center(of = to))
            } else {
                listOf(
                    map.center(of = from), RoutePoint(exit.sign.midX, exit.sign.midY),
                    RoutePoint(entry.sign.midX, entry.sign.midY), map.center(of = to)
                )
            }
        }
        val candidates = requests.mapNotNull { request ->
            access(request, map)?.let { Candidate(request, it.first, it.second, it.third) }
        }
        if (candidates.isEmpty()) return null

        val originCell = origin?.let { map.nearestWalkable(map.cell(at = it)) }
        val candidateFields = candidates.map { pathfinder.costs(it.cell) }

        // A closure can cut a stop off entirely. Only the stops reachable from where the
        // walk starts are kept; the rest are reported so the visitor knows why they vanished.
        val reachCounts = candidates.indices.map { from ->
            candidates.indices.count { candidateFields[from][map.index(candidates[it].cell)].isFinite() }
        }
        val hub = candidates.indices.maxByOrNull { reachCounts[it] } ?: 0
        val reachable = candidates.indices.filter { index ->
            if (originCell != null) {
                candidateFields[index][map.index(originCell)].isFinite()
            } else {
                candidateFields[hub][map.index(candidates[index].cell)].isFinite()
            }
        }
        val skippedSpaces = candidates.indices.filter { it !in reachable }.map { candidates[it].request.spaceName }
        val stops = reachable.map { candidates[it] }
        val fields = reachable.map { candidateFields[it] }
        if (stops.isEmpty()) {
            return PlannedRoute(
                stops = emptyList(), legs = emptyList(), steps = emptyList(), origin = null,
                closures = closureLines, outsidePaths = emptyList(), skippedSpaces = skippedSpaces
            )
        }

        val costs = stops.indices.map { from ->
            FloatArray(stops.size) { to -> fields[from][map.index(stops[to].cell)] }
        }
        val (order, entrance) = order(originCell, doors, map, fields, costs, stops.map { it.request.rank })

        val narrator = RouteNarrator(map, doorName, outside)
        val outsidePaths = mutableListOf<List<RoutePoint>>()
        val plannedStops = mutableListOf<RouteStop>()
        val legs = mutableListOf<List<RoutePoint>>()
        val steps = mutableListOf<RouteStep>()
        var current: GridPoint? = originCell ?: entrance?.cell
        var currentPoint: RoutePoint? = originCell?.let { map.center(of = it) }
            ?: entrance?.let { RoutePoint(it.sign.midX, it.sign.midY) }
        val signPoint = currentPoint
        if (entrance != null && signPoint != null) {
            steps.add(
                RouteStep(
                    id = 0, stopIndex = 0, blocks = 0, action = RouteAction.Entrance(doorName(entrance.cell)),
                    path = listOf(signPoint, map.center(of = entrance.cell))
                )
            )
        }
        pathfinder.wear = FloatArray(map.walkable.size)
        for ((position, index) in order.withIndex()) {
            val stop = stops[index]
            val center = RoutePoint(stop.request.spaceRect.midX, stop.request.spaceRect.midY)
            val addStop: (RoutePoint) -> Unit = { point ->
                plannedStops.add(
                    RouteStop(
                        id = stop.request.webCatalogID, circleID = stop.request.circleID,
                        name = stop.request.name, spaceName = stop.request.spaceName,
                        accessPoint = point, spaceCenter = center, colorRawValue = stop.request.colorRawValue
                    )
                )
            }
            val from = current
            val fromPoint = currentPoint
            if (from == null || fromPoint == null) {
                addStop(stop.point)
                legs.add(listOf(stop.point))
                steps.add(
                    RouteStep(
                        id = steps.size, stopIndex = position, blocks = 0,
                        action = RouteAction.Begin, path = listOf(stop.point)
                    )
                )
                current = stop.cell
                currentPoint = stop.point
                continue
            }
            val cells = pathfinder.path(from, stop.cell)
            val path = cells.ifEmpty { listOf(stop.cell) }
            wear(path, map, pathfinder.wear)
            val segments = RouteNarrator.segments(path)
            val leg = mutableListOf<RoutePoint>()
            for ((segmentIndex, segment) in segments.withIndex()) {
                if (leg.isNotEmpty()) {
                    val lastCell = segments[segmentIndex - 1].last()
                    val walk = outside(lastCell, segment.first())
                    outsidePaths.add(walk)
                    leg += walk.drop(1).dropLast(1)
                }
                val points = segment.map { map.center(of = it) }.toMutableList()
                if (segmentIndex == 0) points.add(0, fromPoint)
                val isLast = segmentIndex == segments.size - 1
                if (isLast) points.add(stop.point)
                leg += RouteStraightener.straighten(points, if (isLast) stop.axis else null)
            }
            val arrival = leg.lastOrNull() ?: stop.point
            addStop(arrival)
            legs.add(leg)
            steps += narrator.steps(path, position, center, steps.size)
            current = stop.cell
            currentPoint = arrival
        }
        return PlannedRoute(
            stops = plannedStops, legs = legs, steps = steps, origin = originCell?.let { map.center(of = it) },
            closures = closureLines, outsidePaths = outsidePaths, skippedSpaces = skippedSpaces
        )
    }

    private fun order(
        originCell: GridPoint?, doors: List<RouteDoor>, map: WalkableMap,
        fields: List<FloatArray>, costs: List<FloatArray>, ranks: List<Int>
    ): Pair<List<Int>, RouteDoor?> {
        if (originCell != null) {
            val startCosts = FloatArray(fields.size) { fields[it][map.index(originCell)] }
            return StopOrderer.order(costs, startCosts, ranks) to null
        }
        bestEntrance(doors, map, fields, costs, ranks)?.let { return it.second to it.first }
        return StopOrderer.order(costs, FloatArray(fields.size), ranks) to null
    }

    /**
     * Without knowing where the visitor stands, they are taken to be outside the hall, so
     * the walk starts at whichever entrance makes the whole route shortest.
     */
    private fun bestEntrance(
        doors: List<RouteDoor>, map: WalkableMap, fields: List<FloatArray>, costs: List<FloatArray>, ranks: List<Int>
    ): Pair<RouteDoor, List<Int>>? {
        var best: Pair<RouteDoor, List<Int>>? = null
        var bestLength = Float.POSITIVE_INFINITY
        for (door in doors) {
            if (!map.isWalkable(door.cell)) continue
            val startCosts = FloatArray(fields.size) { fields[it][map.index(door.cell)] }
            if (!startCosts.all { it.isFinite() }) continue
            val order = StopOrderer.order(costs, startCosts, ranks)
            val length = StopOrderer.length(order, costs, startCosts)
            if (best == null || length < bestLength) {
                best = door to order
                bestLength = length
            }
        }
        return best
    }

    /** The cells each active closure blocks, and the line drawn across each on the map. */
    fun seal(closures: List<RouteClosure>, map: WalkableMap): Pair<List<GridPoint>, List<RouteClosureLine>> {
        val lines = mutableListOf<RouteClosureLine>()
        val blocked = mutableListOf<GridPoint>()
        for (closure in closures) {
            if (!closure.isActive) continue
            val boundaryX = closure.hallBoundaryX
            if (boundaryX != null) {
                val cells = map.boundaryCells(boundaryX)
                blocked += cells
                val top = cells.minOfOrNull { it.row }
                val bottom = cells.maxOfOrNull { it.row }
                if (top != null && bottom != null) {
                    val size = WalkableMap.CELL_SIZE.toDouble()
                    lines.add(
                        RouteClosureLine(
                            closure.id,
                            RoutePoint(boundaryX, top * size),
                            RoutePoint(boundaryX, (bottom + 1) * size)
                        )
                    )
                }
                continue
            }
            val cells = map.closureCells(closure.point, closure.across)
            blocked += cells
            line(cells, map)?.let { lines.add(RouteClosureLine(closure.id, it.first, it.second)) }
        }
        return blocked to lines
    }

    /**
     * Marks a leg's cells and the lanes beside them as walked, so a later leg running
     * alongside it one cell over still counts as the same stretch of aisle.
     */
    private fun wear(path: List<GridPoint>, map: WalkableMap, wear: FloatArray) {
        for (cell in path) {
            for (dy in -1..1) {
                for (dx in -1..1) {
                    val neighbour = GridPoint(cell.row + dy, cell.column + dx)
                    if (!map.contains(neighbour)) continue
                    wear[map.index(neighbour)] = WEAR_PENALTY
                }
            }
        }
    }

    private fun portals(doors: List<RouteDoor>, map: WalkableMap): Map<Int, List<Pathfinder.Portal>> {
        val portals = HashMap<Int, MutableList<Pathfinder.Portal>>()
        val size = WalkableMap.CELL_SIZE.toDouble()
        for (exit in doors) {
            if (!map.isWalkable(exit.cell)) continue
            for (entry in doors) {
                if (entry == exit || entry.edge != exit.edge || !map.isWalkable(entry.cell)) continue
                val distance = hypot(exit.sign.midX - entry.sign.midX, exit.sign.midY - entry.sign.midY) / size
                portals.getOrPut(map.index(exit.cell)) { mutableListOf() }
                    .add(Pathfinder.Portal(map.index(entry.cell), distance.toFloat() + OUTSIDE_PENALTY))
            }
        }
        return portals
    }

    fun line(cells: List<GridPoint>, map: WalkableMap): Pair<RoutePoint, RoutePoint>? {
        val first = cells.firstOrNull() ?: return null
        val sameRow = cells.filter { it.row == first.row }
        val sameColumn = cells.filter { it.column == first.column }
        val band = if (sameRow.size >= sameColumn.size) {
            sameRow.sortedBy { it.column }
        } else {
            sameColumn.sortedBy { it.row }
        }
        val start = band.firstOrNull() ?: return null
        val end = band.lastOrNull() ?: return null
        return map.center(of = start) to map.center(of = end)
    }

    /**
     * The aisle cell in front of a space, and the point in it level with the middle of the
     * space, since a half space covers two cells and either cell's centre sits off its middle.
     */
    fun access(request: RouteStopRequest, map: WalkableMap): Triple<GridPoint, RoutePoint, RoutePoint?>? {
        val cell = accessCell(request, map) ?: return null
        val center = map.center(of = cell)
        val rect = request.spaceRect
        if (rect.minX <= center.x && center.x <= rect.maxX) {
            return Triple(cell, RoutePoint(rect.midX, center.y), RoutePoint(1.0, 0.0))
        }
        if (rect.minY <= center.y && center.y <= rect.maxY) {
            return Triple(cell, RoutePoint(center.x, rect.midY), RoutePoint(0.0, 1.0))
        }
        return Triple(cell, center, null)
    }

    /**
     * The aisle cell in front of a space. Every space has one side facing an aisle; the
     * others touch its neighbours or the island's back row, so the side with the most
     * room in front of it is the one buyers stand on.
     */
    fun accessCell(request: RouteStopRequest, map: WalkableMap): GridPoint? {
        val size = WalkableMap.CELL_SIZE
        val top = request.spaceRect.minY.toInt() / size
        val left = request.spaceRect.minX.toInt() / size
        val bottom = (request.spaceRect.maxY.toInt() - 1) / size
        val right = (request.spaceRect.maxX.toInt() - 1) / size
        val sides = listOf(
            (top..bottom).map { GridPoint(it, left - 1) } to true,
            (top..bottom).map { GridPoint(it, right + 1) } to true,
            (left..right).map { GridPoint(top - 1, it) } to false,
            (left..right).map { GridPoint(bottom + 1, it) } to false
        )
        var bestScore = 0f
        var bestCell: GridPoint? = null
        for ((cells, isSideways) in sides) {
            val open = cells.filter { map.isWalkable(it) }
            if (open.isEmpty()) continue
            var score = open.size * 10.0f
            score += open.fold(0f) { sum, cell -> sum + min(map.clearance[map.index(cell)], 6.0f) }
            if (isSideways == request.opensSideways) score += 5.0f
            if (bestCell == null || score > bestScore) {
                bestScore = score
                bestCell = open[open.size / 2]
            }
        }
        return bestCell ?: map.nearestWalkable(GridPoint((top + bottom) / 2, (left + right) / 2))
    }
}
