package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Hand-drawn, full-colour icons for the ways a route can be planned. */
@Composable
fun NaviModeIcon(kind: NaviModeIconKind, isEnabled: Boolean, size: Dp = 40.dp) {
    val drawing = IconDrawing(isSystemInDarkTheme())
    Canvas(modifier = Modifier.size(size).alpha(if (isEnabled) 1f else 0.5f)) {
        val side = minOf(this.size.width, this.size.height)
        val paint = Paint().apply {
            if (!isEnabled) colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) })
        }
        drawIntoCanvas { canvas ->
            canvas.saveLayer(Rect(Offset.Zero, this.size), paint)
            when (kind) {
                NaviModeIconKind.AUTOMATIC -> drawRoute(drawing, side)
                NaviModeIconKind.COLORS -> drawColors(drawing, side)
                NaviModeIconKind.OWN_BUYS -> drawOwnBuys(drawing, side)
                NaviModeIconKind.SHARED_BUYS -> drawSharedBuys(drawing, side)
            }
            canvas.restore()
        }
    }
}

enum class NaviModeIconKind { AUTOMATIC, COLORS, OWN_BUYS, SHARED_BUYS }

private fun units(points: List<Pair<Float, Float>>, side: Float): List<Offset> =
    points.map { Offset(it.first * side, it.second * side) }

/** Up, right, up, right, then down: the shortest way through every stop. */
private fun DrawScope.drawRoute(drawing: IconDrawing, side: Float) = with(drawing) {
    val points = units(
        listOf(0.14f to 0.86f, 0.14f to 0.54f, 0.44f to 0.54f, 0.44f to 0.2f, 0.8f to 0.2f, 0.8f to 0.58f), side
    )
    drawLine(points, blue, side * 0.11f)
    drawDot(points.first(), 0.09f * side, green)
    drawDot(points.last(), 0.1f * side, red)
}

/** Up, right, down, right, then up, one favourite colour after another. */
private fun DrawScope.drawColors(drawing: IconDrawing, side: Float) = with(drawing) {
    val legs = listOf(
        listOf(0.14f to 0.86f, 0.14f to 0.18f, 0.44f to 0.18f) to orange,
        listOf(0.44f to 0.18f, 0.44f to 0.82f, 0.76f to 0.82f) to pink,
        listOf(0.76f to 0.82f, 0.76f to 0.18f) to cyan
    )
    for ((leg, color) in legs) drawLine(units(leg, side), color, side * 0.11f)
    drawDot(Offset(0.14f * side, 0.86f * side), 0.08f * side, green)
    for ((leg, color) in legs) {
        val end = leg.last()
        drawDot(Offset(end.first * side, end.second * side), 0.1f * side, color)
    }
}

private fun DrawScope.drawOwnBuys(drawing: IconDrawing, side: Float) = with(drawing) {
    drawBag(Rect(Offset(0.19f * side, 0.06f * side), Size(0.62f * side, 0.88f * side)), pink, deepPink)
}

private fun DrawScope.drawSharedBuys(drawing: IconDrawing, side: Float) = with(drawing) {
    drawBag(Rect(Offset(0.42f * side, 0.04f * side), Size(0.5f * side, 0.7f * side)), purple, deepPurple)
    drawBag(Rect(Offset(0.08f * side, 0.26f * side), Size(0.5f * side, 0.7f * side)), teal, deepTeal)
}
