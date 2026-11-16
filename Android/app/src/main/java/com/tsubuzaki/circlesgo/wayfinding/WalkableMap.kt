package com.tsubuzaki.circlesgo.wayfinding

import android.graphics.Bitmap
import kotlin.math.max
import kotlin.math.min

/**
 * Where a visitor can walk on one hall map, as a grid of cells a quarter of a space wide.
 *
 * The catalog places every table exactly, but knows nothing of walls, entrances, stages
 * or spaces that were struck out, so those are read off the map image itself.
 */
class WalkableMap(
    val rows: Int,
    val columns: Int,
    val walkable: BooleanArray,
    val clearance: FloatArray,
    val stepCost: FloatArray,
    val islandLabels: IntArray,
    val islands: List<Island>,
    val doors: List<RouteDoor>
) {

    data class Island(
        val name: String,
        val minRow: Int,
        val maxRow: Int,
        val minColumn: Int,
        val maxColumn: Int
    )

    fun index(point: GridPoint): Int = point.row * columns + point.column

    fun contains(point: GridPoint): Boolean =
        point.row in 0 until rows && point.column in 0 until columns

    fun isWalkable(point: GridPoint): Boolean = contains(point) && walkable[index(point)]

    fun cell(at: RoutePoint): GridPoint =
        GridPoint(row = at.y.toInt() / CELL_SIZE, column = at.x.toInt() / CELL_SIZE)

    fun center(of: GridPoint): RoutePoint {
        val half = CELL_SIZE / 2.0
        return RoutePoint(x = (of.column * CELL_SIZE) + half, y = (of.row * CELL_SIZE) + half)
    }

    fun island(at: GridPoint): Island? {
        if (!contains(at)) return null
        val label = islandLabels[index(at)]
        return if (label > 0) islands[label - 1] else null
    }

    fun nearestWalkable(start: GridPoint): GridPoint? {
        if (isWalkable(start)) return start
        val seen = HashSet<GridPoint>()
        seen.add(start)
        val queue = ArrayDeque<GridPoint>()
        queue.addLast(start)
        while (queue.isNotEmpty()) {
            val current = queue.removeFirst()
            for ((dy, dx) in GridLabels.FOUR_WAYS) {
                val next = GridPoint(current.row + dy, current.column + dx)
                if (!contains(next) || !seen.add(next)) continue
                if (walkable[index(next)]) return next
                queue.addLast(next)
            }
        }
        return null
    }

    fun copy(walkable: BooleanArray = this.walkable, doors: List<RouteDoor> = this.doors): WalkableMap =
        WalkableMap(rows, columns, walkable, clearance, stepCost, islandLabels, islands, doors)

    companion object {

        const val CELL_SIZE: Int = 10

        fun build(image: Bitmap, tables: List<RouteTable>, entrances: HallEntrances): WalkableMap? {
            val width = image.width
            val height = image.height
            if (width <= 0 || height <= 0) return null
            val raster = MapRaster.from(image)

            val thick = Morphology.open(raster.dark, width, height, 7)
            val walls = Morphology.dilate(thick, width, height, 5, 5)
            val zones = Morphology.open(raster.fillOrDark, width, height, 31)

            val tableMask = BooleanArray(width * height)
            for (table in tables) fill(tableMask, table.rect, width, height)

            val edges = EdgeDetector.edges(raster.neutralGray, width, height)
            val enclosed = enclosedRegions(edges, walls, width, height)

            val size = CELL_SIZE
            val rows = height / size
            val columns = width / size
            val blockedFraction = FloatArray(rows * columns)
            val wallCells = BooleanArray(rows * columns)
            val zoneCells = BooleanArray(rows * columns)
            val cellArea = (size * size).toFloat()
            for (row in 0 until rows) {
                for (column in 0 until columns) {
                    var blockedCount = 0
                    var zoneCount = 0
                    var hasWall = false
                    for (y in (row * size) until (row * size + size)) {
                        val base = y * width
                        for (x in (column * size) until (column * size + size)) {
                            val index = base + x
                            if (walls[index] || zones[index] || tableMask[index] || enclosed[index]) blockedCount++
                            if (zones[index]) zoneCount++
                            if (walls[index]) hasWall = true
                        }
                    }
                    val cell = row * columns + column
                    blockedFraction[cell] = blockedCount / cellArea
                    zoneCells[cell] = zoneCount / cellArea > 0.5f
                    wallCells[cell] = hasWall
                }
            }

            var interior = hallInterior(wallCells, zoneCells, rows, columns)
            if (interior.count { it } < rows * columns / 4) {
                interior = aroundTables(tables, rows, columns)
            }
            var walkable = BooleanArray(rows * columns) { interior[it] && blockedFraction[it] < 0.05f }
            walkable = GridLabels.largestComponent(walkable, rows, columns)

            val clearance = distanceToObstacle(walkable, rows, columns)
            val stepCost = FloatArray(clearance.size) { 1.0f + 3.0f / max(clearance[it], 1.0f) }
            val (islandLabels, islands) = islandsOf(tables, rows, columns)

            val map = WalkableMap(rows, columns, walkable, clearance, stepCost, islandLabels, islands, emptyList())
            val doors = when (entrances) {
                is HallEntrances.Signs ->
                    doorSigns(raster, width, height).mapNotNull { map.door(at = it) }
                else -> {
                    val finder = EntranceFinder(raster, width, height, tables)
                    finder.starts(entrances).mapNotNull { map.door(startingAt = it) }
                }
            }
            return map.copy(doors = doors)
        }

        private fun fill(mask: BooleanArray, rect: RouteRect, width: Int, height: Int) {
            val minX = max(0, rect.minX.toInt())
            val maxX = min(width, rect.maxX.toInt())
            val minY = max(0, rect.minY.toInt())
            val maxY = min(height, rect.maxY.toInt())
            if (minX >= maxX || minY >= maxY) return
            for (y in minY until maxY) {
                for (x in minX until maxX) mask[y * width + x] = true
            }
        }

        /**
         * Small regions closed off by edges, such as struck-out spaces and booths missing from
         * the catalog. The hall itself is open to the image border once walls are ignored.
         */
        private fun enclosedRegions(edges: BooleanArray, walls: BooleanArray, width: Int, height: Int): BooleanArray {
            var edgeMask = BooleanArray(width * height) { edges[it] && !walls[it] }
            edgeMask = Morphology.dilate(edgeMask, width, height, 3, 3)
            val open = BooleanArray(edgeMask.size) { !edgeMask[it] }
            val maximumArea = 4 * 40 * 40
            val labels = GridLabels.label(open, height, width)
            val area = IntArray(labels.count + 1)
            val touchesBorder = BooleanArray(labels.count + 1)
            for (row in 0 until height) {
                for (column in 0 until width) {
                    val label = labels.values[row * width + column]
                    if (label <= 0) continue
                    area[label] += 1
                    if (row == 0 || column == 0 || row == height - 1 || column == width - 1) {
                        touchesBorder[label] = true
                    }
                }
            }
            val enclosed = BooleanArray(width * height) {
                val label = labels.values[it]
                label > 0 && !touchesBorder[label] && area[label] < maximumArea
            }
            return Morphology.dilate(enclosed, width, height, 5, 5)
        }

        /**
         * Doors leave gaps in the hall outline, so the walls are closed along straight lines
         * before the outside is flooded in from the image border.
         */
        private fun hallInterior(walls: BooleanArray, zones: BooleanArray, rows: Int, columns: Int): BooleanArray {
            val sealed = walls.copyOf()
            val closings = listOf((0 to 1) to 16, (1 to 0) to 16, (1 to 1) to 8, (1 to -1) to 8)
            for ((direction, length) in closings) {
                val closed = GridLabels.closeAlongLine(walls, rows, columns, direction, length)
                for (index in sealed.indices) if (closed[index]) sealed[index] = true
            }
            val open = BooleanArray(rows * columns) { !sealed[it] && !zones[it] }
            val labels = GridLabels.label(open, rows, columns)
            val area = IntArray(labels.count + 1)
            val touchesBorder = BooleanArray(labels.count + 1)
            for (row in 0 until rows) {
                for (column in 0 until columns) {
                    val label = labels.values[row * columns + column]
                    if (label <= 0) continue
                    area[label] += 1
                    if (row == 0 || column == 0 || row == rows - 1 || column == columns - 1) {
                        touchesBorder[label] = true
                    }
                }
            }
            val hall = (1..labels.count).filter { !touchesBorder[it] }.maxByOrNull { area[it] }
                ?: return BooleanArray(rows * columns) { true }
            val outsideOfHall = BooleanArray(rows * columns) { labels.values[it] != hall }
            val outside = GridLabels.reachableFromBorder(outsideOfHall, rows, columns)
            return BooleanArray(outside.size) { !outside[it] }
        }

        /**
         * Where the outline has door gaps too wide to seal, the outside floods into the hall.
         * The tables' extent, padded out to reach the corridors along the walls, stands in.
         */
        private fun aroundTables(tables: List<RouteTable>, rows: Int, columns: Int): BooleanArray {
            val first = tables.firstOrNull()?.rect ?: return BooleanArray(rows * columns) { true }
            val bounds = tables.fold(first) { result, table -> result.union(table.rect) }
            val pad = 15
            val top = max(0, bounds.minY.toInt() / CELL_SIZE - pad)
            val bottom = min(rows - 1, bounds.maxY.toInt() / CELL_SIZE + pad)
            val left = max(0, bounds.minX.toInt() / CELL_SIZE - pad)
            val right = min(columns - 1, bounds.maxX.toInt() / CELL_SIZE + pad)
            val interior = BooleanArray(rows * columns)
            for (row in top..bottom) {
                for (column in left..right) interior[row * columns + column] = true
            }
            return interior
        }

        private fun distanceToObstacle(walkable: BooleanArray, rows: Int, columns: Int): FloatArray {
            val far = 1_000_000f
            val distance = FloatArray(walkable.size) { if (walkable[it]) far else 0f }
            val diagonal = 1.41421356f
            for (row in 0 until rows) {
                for (column in 0 until columns) {
                    val index = row * columns + column
                    if (distance[index] <= 0f) continue
                    var best = distance[index]
                    if (row > 0) best = min(best, distance[index - columns] + 1)
                    if (column > 0) best = min(best, distance[index - 1] + 1)
                    if (row > 0 && column > 0) best = min(best, distance[index - columns - 1] + diagonal)
                    if (row > 0 && column < columns - 1) best = min(best, distance[index - columns + 1] + diagonal)
                    if (row == 0 || column == 0 || row == rows - 1 || column == columns - 1) best = min(best, 1f)
                    distance[index] = best
                }
            }
            for (row in rows - 1 downTo 0) {
                for (column in columns - 1 downTo 0) {
                    val index = row * columns + column
                    if (distance[index] <= 0f) continue
                    var best = distance[index]
                    if (row < rows - 1) best = min(best, distance[index + columns] + 1)
                    if (column < columns - 1) best = min(best, distance[index + 1] + 1)
                    if (row < rows - 1 && column < columns - 1) best = min(best, distance[index + columns + 1] + diagonal)
                    if (row < rows - 1 && column > 0) best = min(best, distance[index + columns - 1] + diagonal)
                    distance[index] = best
                }
            }
            return distance
        }

        private fun islandsOf(tables: List<RouteTable>, rows: Int, columns: Int): Pair<IntArray, List<Island>> {
            val occupied = BooleanArray(rows * columns)
            val owners = mutableListOf<Pair<GridPoint, String>>()
            for (table in tables) {
                val minRow = max(0, table.rect.minY.toInt() / CELL_SIZE)
                val maxRow = min(rows - 1, (table.rect.maxY.toInt() - 1) / CELL_SIZE)
                val minColumn = max(0, table.rect.minX.toInt() / CELL_SIZE)
                val maxColumn = min(columns - 1, (table.rect.maxX.toInt() - 1) / CELL_SIZE)
                if (minRow > maxRow || minColumn > maxColumn) continue
                for (row in minRow..maxRow) {
                    for (column in minColumn..maxColumn) occupied[row * columns + column] = true
                }
                owners.add(GridPoint(minRow, minColumn) to table.blockName)
            }
            val grown = occupied.copyOf()
            for (row in 0 until rows) {
                for (column in 0 until columns) {
                    if (!occupied[row * columns + column]) continue
                    for (dy in -1..1) {
                        for (dx in -1..1) {
                            val nextRow = row + dy
                            val nextColumn = column + dx
                            if (nextRow in 0 until rows && nextColumn in 0 until columns) {
                                grown[nextRow * columns + nextColumn] = true
                            }
                        }
                    }
                }
            }
            val grownLabels = GridLabels.label(grown, rows, columns)
            val names = List(grownLabels.count + 1) { HashMap<String, Int>() }
            for ((cell, name) in owners) {
                val label = grownLabels.values[cell.row * columns + cell.column]
                names[label][name] = (names[label][name] ?: 0) + 1
            }
            val minRows = IntArray(grownLabels.count + 1) { Int.MAX_VALUE }
            val maxRows = IntArray(grownLabels.count + 1) { -1 }
            val minColumns = IntArray(grownLabels.count + 1) { Int.MAX_VALUE }
            val maxColumns = IntArray(grownLabels.count + 1) { -1 }
            val labels = IntArray(rows * columns)
            for (row in 0 until rows) {
                for (column in 0 until columns) {
                    if (!occupied[row * columns + column]) continue
                    val label = grownLabels.values[row * columns + column]
                    labels[row * columns + column] = label
                    minRows[label] = min(minRows[label], row)
                    maxRows[label] = max(maxRows[label], row)
                    minColumns[label] = min(minColumns[label], column)
                    maxColumns[label] = max(maxColumns[label], column)
                }
            }
            val islands = (1..grownLabels.count).map { label ->
                val name = names[label].maxByOrNull { it.value }?.key ?: ""
                Island(name, minRows[label], maxRows[label], minColumns[label], maxColumns[label])
            }
            return labels to islands
        }
    }
}
