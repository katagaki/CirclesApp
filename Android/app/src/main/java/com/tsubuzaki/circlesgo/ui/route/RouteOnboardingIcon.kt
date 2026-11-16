package com.tsubuzaki.circlesgo.ui.route

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.ui.navi.IconDrawing

enum class RouteOnboardingIconKind { MODES, ORIGIN, STEPS, DETOUR }

/** Hand-drawn icons for the Guide onboarding, in the style of the route mode icons. */
@Composable
fun RouteOnboardingIcon(kind: RouteOnboardingIconKind, size: Dp = 36.dp) {
    val drawing = IconDrawing(isSystemInDarkTheme())
    Canvas(modifier = Modifier.size(size)) {
        val side = minOf(this.size.width, this.size.height)
        when (kind) {
            RouteOnboardingIconKind.MODES -> drawModes(drawing, side)
            RouteOnboardingIconKind.ORIGIN -> drawOrigin(drawing, side)
            RouteOnboardingIconKind.STEPS -> drawSteps(drawing, side)
            RouteOnboardingIconKind.DETOUR -> drawDetour(drawing, side)
        }
    }
}

private fun points(units: List<Pair<Float, Float>>, side: Float): List<Offset> =
    units.map { Offset(it.first * side, it.second * side) }

/** One start, two ways: a single blue line, or one colour after another. */
private fun DrawScope.drawModes(drawing: IconDrawing, side: Float) = with(drawing) {
    val width = side * 0.11f
    val blue = points(listOf(0.14f to 0.86f, 0.14f to 0.16f, 0.84f to 0.16f), side)
    val orange = points(listOf(0.14f to 0.86f, 0.5f to 0.86f, 0.5f to 0.5f), side)
    val pink = points(listOf(0.5f to 0.5f, 0.84f to 0.5f), side)
    drawLine(blue, drawing.blue, width)
    drawLine(orange, drawing.orange, width)
    drawLine(pink, drawing.pink, width)
    drawDot(blue[0], 0.09f * side, green)
    drawDot(blue[2], 0.09f * side, red)
    drawDot(orange[2], 0.09f * side, drawing.orange)
    drawDot(pink[1], 0.09f * side, drawing.pink)
}

/** The current location dot, with the rings a long press leaves behind. */
private fun DrawScope.drawOrigin(drawing: IconDrawing, side: Float) = with(drawing) {
    val center = Offset(side * 0.5f, side * 0.5f)
    drawCircle(blue.copy(alpha = 0.18f), 0.46f * side, center)
    drawCircle(blue.copy(alpha = 0.32f), 0.32f * side, center)
    drawDot(center, 0.17f * side, blue)
}

/** Stops already passed, and the button that moves on to the next one. */
private fun DrawScope.drawSteps(drawing: IconDrawing, side: Float) = with(drawing) {
    val line = points(listOf(0.12f to 0.5f, 0.62f to 0.5f), side)
    drawLine(line, Color.Gray.copy(alpha = 0.6f), side * 0.08f)
    drawDot(line[0], 0.08f * side, Color.Gray)
    drawDot(Offset(side * 0.37f, side * 0.5f), 0.08f * side, Color.Gray)
    val center = Offset(side * 0.7f, side * 0.5f)
    drawCircle(green, side * 0.24f, center)
    drawCircle(outline, side * 0.24f, center, style = Stroke(width = side * 0.04f))
    drawLine(points(listOf(0.66f to 0.38f, 0.77f to 0.5f, 0.66f to 0.62f), side), Color.White, side * 0.08f)
}

/** A closed aisle on the straight way, and the route bending around it. */
private fun DrawScope.drawDetour(drawing: IconDrawing, side: Float) = with(drawing) {
    drawLine(points(listOf(0.14f to 0.76f, 0.86f to 0.76f), side), Color.Gray.copy(alpha = 0.4f), side * 0.08f)
    val around = points(
        listOf(0.14f to 0.76f, 0.3f to 0.76f, 0.3f to 0.24f, 0.7f to 0.24f, 0.7f to 0.76f, 0.86f to 0.76f), side
    )
    drawLine(around, blue, side * 0.11f)
    val topLeft = Offset(side * 0.44f, side * 0.56f)
    val barSize = Size(side * 0.12f, side * 0.4f)
    drawRoundRect(red, topLeft, barSize, CornerRadius(side * 0.06f))
    drawRoundRect(outline, topLeft, barSize, CornerRadius(side * 0.06f), style = Stroke(width = side * 0.04f))
    drawDot(around[0], 0.09f * side, green)
    drawDot(around[5], 0.09f * side, red)
}
