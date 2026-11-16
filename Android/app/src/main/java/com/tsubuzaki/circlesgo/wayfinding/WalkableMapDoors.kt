package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.max
import kotlin.math.min

/** A way in that starts on open floor at the point given. */
fun WalkableMap.door(startingAt: RoutePoint): RouteDoor? {
    val cell = nearestWalkable(cell(at = startingAt)) ?: return null
    return RouteDoor(cell, RouteRect(startingAt.x - 1, startingAt.y - 1, 2.0, 2.0), RouteDoor.Edge.BOTTOM)
}

/**
 * Ties a hall sign on the map's edge to the floor just inside it, which is where the
 * door it names opens into the hall.
 */
fun WalkableMap.door(at: RouteRect): RouteDoor? {
    val size = WalkableMap.CELL_SIZE.toDouble()
    val width = columns * size
    val height = rows * size
    val gaps = listOf(
        RouteDoor.Edge.TOP to at.minY,
        RouteDoor.Edge.BOTTOM to height - at.maxY,
        RouteDoor.Edge.LEFT to at.minX,
        RouteDoor.Edge.RIGHT to width - at.maxX
    )
    val edge = gaps.minByOrNull { it.second }?.first ?: return null
    val inside = when (edge) {
        RouteDoor.Edge.TOP -> RoutePoint(at.midX, at.maxY + size * 3)
        RouteDoor.Edge.BOTTOM -> RoutePoint(at.midX, at.minY - size * 3)
        RouteDoor.Edge.LEFT -> RoutePoint(at.maxX + size * 3, at.midY)
        RouteDoor.Edge.RIGHT -> RoutePoint(at.minX - size * 3, at.midY)
    }
    val cell = nearestWalkable(cell(at = inside)) ?: return null
    return RouteDoor(cell, at, edge, isSign = true)
}

/**
 * Hall signs: solid dark plates with white lettering, set flush against the edge of the
 * map. Stair and escalator blocks are as dark but sit inside the hall, away from it.
 */
fun doorSigns(raster: MapRaster, width: Int, height: Int): List<RouteRect> {
    val closed = Morphology.erode(
        Morphology.dilate(raster.dark, width, height, 9, 9),
        width, height, 9, 9
    )
    val plates = Morphology.open(closed, width, height, 25)
    val labels = GridLabels.label(plates, height, width)
    if (labels.count <= 0) return emptyList()
    val minX = IntArray(labels.count + 1) { Int.MAX_VALUE }
    val maxX = IntArray(labels.count + 1) { -1 }
    val minY = IntArray(labels.count + 1) { Int.MAX_VALUE }
    val maxY = IntArray(labels.count + 1) { -1 }
    for (y in 0 until height) {
        for (x in 0 until width) {
            val label = labels.values[y * width + x]
            if (label <= 0) continue
            minX[label] = min(minX[label], x)
            maxX[label] = max(maxX[label], x)
            minY[label] = min(minY[label], y)
            maxY[label] = max(maxY[label], y)
        }
    }
    val signs = mutableListOf<RouteRect>()
    for (label in 1..labels.count) {
        val boxWidth = maxX[label] - minX[label] + 1
        val boxHeight = maxY[label] - minY[label] + 1
        if (boxHeight !in 40..200 || boxWidth !in 60..260) continue
        val edgeGap = minOf(minX[label], minY[label], width - 1 - maxX[label], height - 1 - maxY[label])
        if (edgeGap > 8) continue
        var white = 0
        for (y in minY[label]..maxY[label]) {
            for (x in minX[label]..maxX[label]) {
                if (raster.grayAt(y * width + x) > 200) white += 1
            }
        }
        if (white.toDouble() / (boxWidth * boxHeight).toDouble() <= 0.05) continue
        signs.add(
            RouteRect(minX[label].toDouble(), minY[label].toDouble(), boxWidth.toDouble(), boxHeight.toDouble())
        )
    }
    return signs
}
