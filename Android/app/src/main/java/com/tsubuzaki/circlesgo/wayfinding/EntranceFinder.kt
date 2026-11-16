package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * Finds where a walk into a hall starts, working at a quarter of the map's resolution.
 * Every start is the middle of the open white floor at that entrance.
 */
class EntranceFinder(
    private val raster: MapRaster,
    private val fullWidth: Int,
    private val fullHeight: Int,
    private val tables: List<RouteTable>
) {

    private val width = fullWidth / SCALE
    private val height = fullHeight / SCALE
    private val booth: BooleanArray
    private val walls: BooleanArray
    private val white: BooleanArray

    init {
        val boothPixels = BooleanArray(fullWidth * fullHeight)
        for (table in tables) {
            val rect = table.rect.insetBy(-4.0, -4.0)
            val minY = max(0, rect.minY.toInt())
            val maxY = min(fullHeight, rect.maxY.toInt())
            val minX = max(0, rect.minX.toInt())
            val maxX = min(fullWidth, rect.maxX.toInt())
            if (minY >= maxY || minX >= maxX) continue
            for (y in minY until maxY) {
                for (x in minX until maxX) boothPixels[y * fullWidth + x] = true
            }
        }
        val booth = BooleanArray(width * height)
        var walls = BooleanArray(width * height)
        val lit = BooleanArray(width * height)
        for (y in 0 until height) {
            for (x in 0 until width) {
                var hasBooth = false
                var hasWall = false
                var allWhite = true
                for (pixelY in (y * SCALE) until (y * SCALE + SCALE)) {
                    for (pixelX in (x * SCALE) until (x * SCALE + SCALE)) {
                        val index = pixelY * fullWidth + pixelX
                        if (boothPixels[index]) hasBooth = true else if (raster.dark[index]) hasWall = true
                        if (raster.grayAt(index) < 235) allWhite = false
                    }
                }
                booth[y * width + x] = hasBooth
                walls[y * width + x] = hasWall
                lit[y * width + x] = allWhite && !hasBooth
            }
        }
        walls = Morphology.dilate(walls, width, height, 3, 3)
        this.booth = booth
        this.walls = walls
        this.white = BooleanArray(lit.size) { lit[it] && !walls[it] }
    }

    fun starts(entrances: HallEntrances): List<RoutePoint> = when (entrances) {
        is HallEntrances.Signs -> emptyList()
        is HallEntrances.Fixed -> listOf(RoutePoint(entrances.x * fullWidth, entrances.y * fullHeight))
        is HallEntrances.Vestibules -> vestibuleStarts()
        is HallEntrances.BottomEdge -> {
            val starts = bottomEdgeStarts(entrances.requiresClearFloor)
            if (!entrances.alignsStarts || starts.isEmpty()) {
                starts
            } else {
                val row = starts.map { it.y }.sorted()[starts.size / 2]
                starts.map { RoutePoint(it.x, row) }
            }
        }
    }

    /**
     * Gaps in the bottom edge wide enough to walk through, with floor clear of walls and
     * booths just inside them.
     */
    private fun bottomEdgeStarts(requiresClearFloor: Boolean): List<RoutePoint> {
        val starts = mutableListOf<RoutePoint>()
        var runStart: Int? = null
        fun close(end: Int) {
            val start = runStart
            runStart = null
            if (start == null || end - start + 1 < 24) return
            if (requiresClearFloor && !opensIntoHall((start + end) / 2)) return
            val point = middle { x, y -> x in start..end && y >= height - EDGE_BAND }
            starts.add(
                point ?: RoutePoint(((start + end) / 2 * SCALE).toDouble(), (fullHeight - 1).toDouble())
            )
        }
        for (x in 0 until width) {
            val isClear = (0 until 6).all { depth ->
                val index = (height - 1 - depth) * width + x
                !walls[index] && !booth[index]
            }
            if (isClear) {
                if (runStart == null) runStart = x
            } else {
                close(x - 1)
            }
        }
        close(width - 1)
        return starts
    }

    /**
     * Open floor runs straight up from the gap into the hall, rather than into a room drawn
     * in thin outline beside it.
     */
    private fun opensIntoHall(column: Int): Boolean {
        val center = column * SCALE
        for (depth in 0 until 150) {
            val row = fullHeight - 1 - depth
            if (row < 0) break
            for (x in max(0, center - 6)..min(fullWidth - 1, center + 6)) {
                if (raster.grayAt(row * fullWidth + x) < 200) return false
            }
        }
        return true
    }

    /**
     * Sealing every gap in the walls splits the map into halls, which have booths, and open
     * areas outside them. The gaps the sealing filled between the two are the vestibules,
     * and each place a vestibule meets a hall is a way in.
     */
    private fun vestibuleStarts(): List<RoutePoint> {
        val count = width * height
        val sealed = Morphology.erode(
            Morphology.dilate(walls, width, height, SEAL, SEAL),
            width, height, SEAL, SEAL
        )
        val regions = GridLabels.label(BooleanArray(count) { !sealed[it] }, height, width)
        val area = IntArray(regions.count + 1)
        val booths = IntArray(regions.count + 1)
        val touchesEdge = BooleanArray(regions.count + 1)
        for (index in 0 until count) area[regions.values[index]] += 1
        for (table in tables) {
            val x = table.rect.midX.toInt() / SCALE
            val y = table.rect.midY.toInt() / SCALE
            if (x < 0 || y < 0 || x >= width || y >= height) continue
            booths[regions.values[y * width + x]] += 1
        }
        for (x in 0 until width) {
            touchesEdge[regions.values[x]] = true
            touchesEdge[regions.values[(height - 1) * width + x]] = true
        }
        for (y in 0 until height) {
            touchesEdge[regions.values[y * width]] = true
            touchesEdge[regions.values[y * width + width - 1]] = true
        }
        val interior = BooleanArray(count)
        val outside = BooleanArray(count)
        for (index in 0 until count) {
            val region = regions.values[index]
            if (region <= 0 || !(area[region] >= 250 || touchesEdge[region])) continue
            if (booths[region] >= 20) interior[index] = true else outside[index] = true
        }

        val gaps = BooleanArray(count) { sealed[it] && !walls[it] }
        val gapLabels = GridLabels.label(gaps, height, width)
        if (gapLabels.count <= 0) return emptyList()
        val boxMinX = IntArray(gapLabels.count + 1) { Int.MAX_VALUE }
        val boxMaxX = IntArray(gapLabels.count + 1) { -1 }
        val boxMinY = IntArray(gapLabels.count + 1) { Int.MAX_VALUE }
        val boxMaxY = IntArray(gapLabels.count + 1) { -1 }
        val meetsHall = IntArray(gapLabels.count + 1)
        val meetsOutside = IntArray(gapLabels.count + 1)
        val contact = BooleanArray(count)
        for (y in 1 until height - 1) {
            for (x in 1 until width - 1) {
                val label = gapLabels.values[y * width + x]
                if (label <= 0) continue
                boxMinX[label] = min(boxMinX[label], x)
                boxMaxX[label] = max(boxMaxX[label], x)
                boxMinY[label] = min(boxMinY[label], y)
                boxMaxY[label] = max(boxMaxY[label], y)
                for ((dx, dy) in listOf(1 to 0, -1 to 0, 0 to 1, 0 to -1)) {
                    val neighbour = (y + dy) * width + x + dx
                    if (interior[neighbour]) {
                        meetsHall[label] += 1
                        contact[y * width + x] = true
                    }
                    if (outside[neighbour]) meetsOutside[label] += 1
                }
            }
        }
        val contacts = GridLabels.label(Morphology.dilate(contact, width, height, 9, 9), height, width)

        val starts = mutableListOf<RoutePoint>()
        for (label in 1..gapLabels.count) {
            if (meetsHall[label] < 5 || meetsOutside[label] < 5) continue
            val minX = boxMinX[label]
            val maxX = boxMaxX[label]
            val minY = boxMinY[label]
            val maxY = boxMaxY[label]
            val stretches = HashMap<Int, IntArray>()
            for (y in minY..maxY) {
                for (x in minX..maxX) {
                    if (!contact[y * width + x]) continue
                    val stretch = contacts.values[y * width + x]
                    val sum = stretches.getOrPut(stretch) { IntArray(3) }
                    sum[0] += x
                    sum[1] += y
                    sum[2] += 1
                }
            }
            for (sum in stretches.values.sortedBy { it[0] }) {
                if (sum[2] < 8) continue
                val centerX = sum[0] / sum[2]
                val centerY = sum[1] / sum[2]
                val point = middle { x, y ->
                    x in minX..maxX && y in minY..maxY &&
                        gaps[y * width + x] && abs(x - centerX) <= 40 && abs(y - centerY) <= 40
                }
                if (point != null) starts.add(point)
            }
        }
        return starts
    }

    /**
     * The white floor cell furthest from anything that is not white floor, among the cells
     * allowed, in full map pixels.
     */
    private fun middle(allowed: (Int, Int) -> Boolean): RoutePoint? {
        val distance = IntArray(width * height)
        for (index in distance.indices) {
            if (white[index] && allowed(index % width, index / width)) distance[index] = Int.MAX_VALUE / 2
        }
        for (y in 0 until height) {
            for (x in 0 until width) {
                val index = y * width + x
                if (distance[index] <= 0) continue
                distance[index] = minOf(
                    distance[index],
                    if (x > 0) distance[index - 1] + 1 else 1,
                    if (y > 0) distance[index - width] + 1 else 1
                )
            }
        }
        for (y in height - 1 downTo 0) {
            for (x in width - 1 downTo 0) {
                val index = y * width + x
                if (distance[index] <= 0) continue
                distance[index] = minOf(
                    distance[index],
                    if (x < width - 1) distance[index + 1] + 1 else 1,
                    if (y < height - 1) distance[index + width] + 1 else 1
                )
            }
        }
        var best = -1
        for (index in distance.indices) {
            if (best < 0 || distance[index] > distance[best]) best = index
        }
        if (best < 0 || distance[best] <= 0) return null
        val half = SCALE / 2
        return RoutePoint(
            (best % width * SCALE + half).toDouble(),
            (best / width * SCALE + half).toDouble()
        )
    }

    companion object {
        const val SCALE = 4
        const val SEAL = 61
        const val EDGE_BAND = 40
    }
}
