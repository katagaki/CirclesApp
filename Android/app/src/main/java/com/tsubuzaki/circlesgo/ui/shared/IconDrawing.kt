package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke

/** Colours and pieces shared by the hand-drawn icons, mirroring iOS's IconDrawing. */
class IconDrawing(isDark: Boolean) {

    private val dark = isDark

    private fun adaptive(light: Triple<Float, Float, Float>, dark: Triple<Float, Float, Float>): Color {
        val rgb = if (this.dark) dark else light
        return Color(rgb.first, rgb.second, rgb.third)
    }

    val outline = adaptive(Triple(0f, 0f, 0f), Triple(1f, 1f, 1f))
    val blue = adaptive(Triple(0f, 0.45f, 0.93f), Triple(0.25f, 0.52f, 0.98f))
    val green = adaptive(Triple(0.16f, 0.66f, 0.29f), Triple(0.2f, 0.78f, 0.35f))
    val deepGreen = adaptive(Triple(0.06f, 0.48f, 0.18f), Triple(0.1f, 0.58f, 0.24f))
    val red = adaptive(Triple(0.9f, 0.2f, 0.2f), Triple(0.96f, 0.27f, 0.27f))
    val deepRed = adaptive(Triple(0.68f, 0.1f, 0.12f), Triple(0.76f, 0.16f, 0.18f))
    val pink = adaptive(Triple(0.93f, 0.25f, 0.5f), Triple(0.98f, 0.36f, 0.6f))
    val deepPink = adaptive(Triple(0.7f, 0.1f, 0.35f), Triple(0.78f, 0.15f, 0.42f))
    val purple = adaptive(Triple(0.55f, 0.3f, 0.88f), Triple(0.64f, 0.4f, 0.95f))
    val deepPurple = adaptive(Triple(0.38f, 0.18f, 0.66f), Triple(0.45f, 0.24f, 0.75f))
    val teal = adaptive(Triple(0f, 0.62f, 0.58f), Triple(0.1f, 0.74f, 0.7f))
    val deepTeal = adaptive(Triple(0f, 0.44f, 0.42f), Triple(0.04f, 0.52f, 0.5f))

    fun roundedRect(rect: Rect, radius: Float): Path =
        Path().apply { addRoundRect(RoundRect(rect, CornerRadius(radius))) }

    fun oval(rect: Rect): Path = Path().apply { addOval(rect) }

    fun DrawScope.drawPolyline(points: List<Offset>, color: Color, width: Float) {
        val path = Path().apply {
            moveTo(points.first().x, points.first().y)
            points.drop(1).forEach { lineTo(it.x, it.y) }
        }
        drawPath(path, color, style = Stroke(width = width, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }

    /** Fills [path] with a top-to-bottom gradient across [rect], then outlines it. */
    fun DrawScope.fillOutlined(path: Path, rect: Rect, top: Color, bottom: Color, lineWidth: Float) {
        drawPath(path, Brush.verticalGradient(listOf(top, bottom), startY = rect.top, endY = rect.bottom))
        drawPath(path, outline, style = Stroke(width = lineWidth, join = StrokeJoin.Round))
    }

    /** A shopping bag filling [rect]: a tall body, with a handle rising out from behind it. */
    fun DrawScope.drawBag(rect: Rect, body: Color, handle: Color) {
        val outlineWidth = rect.width * 0.045f
        val band = rect.width * 0.11f
        val handleRect = Rect(
            offset = Offset(rect.left + rect.width * 0.2f, rect.top + band / 2f),
            size = Size(rect.width * 0.6f, rect.height * 0.5f)
        )
        drawPath(roundedRect(handleRect, rect.width * 0.2f), handle, style = Stroke(width = band))
        val bodyRect = Rect(
            offset = Offset(rect.left + outlineWidth / 2f, rect.top + rect.height * 0.22f),
            size = Size(
                rect.width - outlineWidth,
                rect.height * 0.78f - outlineWidth / 2f
            )
        )
        fillOutlined(roundedRect(bodyRect, rect.width * 0.13f), bodyRect, body, handle, outlineWidth)
    }
}
