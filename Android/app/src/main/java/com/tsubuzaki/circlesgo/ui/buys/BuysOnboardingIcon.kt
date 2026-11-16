package com.tsubuzaki.circlesgo.ui.buys

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.ui.shared.IconDrawing

enum class BuysOnboardingIconKind { ADD, TRACK, SHARE, SPLIT }

/** Hand-drawn icons for the Buys onboarding, in the style of the route mode icons. */
@Composable
fun BuysOnboardingIcon(kind: BuysOnboardingIconKind, size: Dp = 36.dp) {
    val isDark = isSystemInDarkTheme()
    val drawing = remember(isDark) { IconDrawing(isDark) }
    Canvas(modifier = Modifier.size(size)) {
        val side = minOf(this.size.width, this.size.height)
        when (kind) {
            BuysOnboardingIconKind.ADD -> drawAdd(drawing, side)
            BuysOnboardingIconKind.TRACK -> drawTrack(drawing, side)
            BuysOnboardingIconKind.SHARE -> drawShare(drawing, side)
            BuysOnboardingIconKind.SPLIT -> drawSplit(drawing, side)
        }
    }
}

private fun unitRect(x: Float, y: Float, width: Float, height: Float, side: Float) =
    Rect(x * side, y * side, (x + width) * side, (y + height) * side)

private fun circleRect(x: Float, y: Float, radius: Float, side: Float) =
    Rect(Offset(x * side, y * side), radius * side)

private fun DrawScope.mark(drawing: IconDrawing, units: List<Pair<Float, Float>>, side: Float) {
    with(drawing) {
        drawPolyline(units.map { Offset(it.first * side, it.second * side) }, Color.White, side * 0.08f)
    }
}

/** A bag with a plus badge. */
private fun DrawScope.drawAdd(drawing: IconDrawing, side: Float) {
    with(drawing) {
        drawBag(unitRect(0.08f, 0.04f, 0.6f, 0.86f, side), pink, deepPink)
        val badge = circleRect(0.73f, 0.73f, 0.23f, side)
        fillOutlined(oval(badge), badge, green, deepGreen, side * 0.045f)
    }
    mark(drawing, listOf(0.73f to 0.62f, 0.73f to 0.84f), side)
    mark(drawing, listOf(0.62f to 0.73f, 0.84f to 0.73f), side)
}

/** Tap once for bought, twice for couldn't buy. */
private fun DrawScope.drawTrack(drawing: IconDrawing, side: Float) {
    with(drawing) {
        val missed = circleRect(0.33f, 0.33f, 0.27f, side)
        fillOutlined(oval(missed), missed, red, deepRed, side * 0.045f)
    }
    mark(drawing, listOf(0.24f to 0.24f, 0.42f to 0.42f), side)
    mark(drawing, listOf(0.42f to 0.24f, 0.24f to 0.42f), side)
    with(drawing) {
        val bought = circleRect(0.62f, 0.62f, 0.33f, side)
        fillOutlined(oval(bought), bought, green, deepGreen, side * 0.045f)
    }
    mark(drawing, listOf(0.48f to 0.63f, 0.58f to 0.73f, 0.77f to 0.52f), side)
}

/** A QR code for friends to join with. */
private fun DrawScope.drawShare(drawing: IconDrawing, side: Float) {
    with(drawing) {
        val tile = roundedRect(unitRect(0.08f, 0.08f, 0.84f, 0.84f, side), 0.16f * side)
        drawPath(tile, Color.White)
        drawPath(tile, outline, style = Stroke(width = side * 0.045f))
        val ink = Color.Black
        listOf(0.2f to 0.2f, 0.56f to 0.2f, 0.2f to 0.56f).forEach { (x, y) ->
            val outer = unitRect(x, y, 0.24f, 0.24f, side)
            drawPath(
                roundedRect(outer.deflate(0.03f * side), 0.04f * side),
                ink,
                style = Stroke(width = 0.06f * side)
            )
            drawPath(roundedRect(outer.deflate(0.08f * side), 0.02f * side), blue)
        }
        listOf(0.56f to 0.56f, 0.7f to 0.56f, 0.63f to 0.66f, 0.56f to 0.72f, 0.72f to 0.72f).forEach { (x, y) ->
            drawPath(roundedRect(unitRect(x, y, 0.1f, 0.1f, side), 0.02f * side), ink)
        }
    }
}

/** Two friends sharing the list. */
private fun DrawScope.drawSplit(drawing: IconDrawing, side: Float) {
    with(drawing) {
        drawPerson(drawing, unitRect(0.03f, 0.06f, 0.52f, 0.8f, side), purple, deepPurple)
        drawPerson(drawing, unitRect(0.42f, 0.16f, 0.55f, 0.8f, side), teal, deepTeal)
    }
}

private fun DrawScope.drawPerson(drawing: IconDrawing, rect: Rect, top: Color, bottom: Color) {
    with(drawing) {
        val lineWidth = rect.width * 0.08f
        val bodyRect = Rect(rect.left, rect.top + rect.height * 0.5f, rect.right, rect.bottom)
        fillOutlined(roundedRect(bodyRect, rect.width * 0.4f), bodyRect, top, bottom, lineWidth)
        val headRect = Rect(Offset(rect.center.x, rect.top + rect.height * 0.27f), rect.width * 0.27f)
        fillOutlined(oval(headRect), headRect, top, bottom, lineWidth)
    }
}
