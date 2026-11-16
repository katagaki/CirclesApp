package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke

/** Colours and pieces shared by the hand-drawn icons. */
class IconDrawing(isDark: Boolean) {

    private fun adaptive(light: Triple<Float, Float, Float>, dark: Triple<Float, Float, Float>, isDark: Boolean): Color {
        val rgb = if (isDark) dark else light
        return Color(rgb.first, rgb.second, rgb.third)
    }

    val outline = adaptive(Triple(0f, 0f, 0f), Triple(1f, 1f, 1f), isDark)
    val blue = adaptive(Triple(0f, 0.45f, 0.93f), Triple(0.25f, 0.52f, 0.98f), isDark)
    val green = adaptive(Triple(0.16f, 0.66f, 0.29f), Triple(0.2f, 0.78f, 0.35f), isDark)
    val red = adaptive(Triple(0.9f, 0.2f, 0.2f), Triple(0.96f, 0.27f, 0.27f), isDark)
    val orange = adaptive(Triple(0.95f, 0.5f, 0.15f), Triple(1f, 0.58f, 0.29f), isDark)
    val pink = adaptive(Triple(0.93f, 0.25f, 0.5f), Triple(0.98f, 0.36f, 0.6f), isDark)
    val deepPink = adaptive(Triple(0.7f, 0.1f, 0.35f), Triple(0.78f, 0.15f, 0.42f), isDark)
    val cyan = adaptive(Triple(0f, 0.6f, 0.88f), Triple(0f, 0.71f, 1f), isDark)
    val purple = adaptive(Triple(0.55f, 0.3f, 0.88f), Triple(0.64f, 0.4f, 0.95f), isDark)
    val deepPurple = adaptive(Triple(0.38f, 0.18f, 0.66f), Triple(0.45f, 0.24f, 0.75f), isDark)
    val teal = adaptive(Triple(0f, 0.62f, 0.58f), Triple(0.1f, 0.74f, 0.7f), isDark)
    val deepTeal = adaptive(Triple(0f, 0.44f, 0.42f), Triple(0.04f, 0.52f, 0.5f), isDark)

    fun DrawScope.drawLine(points: List<Offset>, color: Color, width: Float) {
        if (points.isEmpty()) return
        val path = Path().apply {
            moveTo(points[0].x, points[0].y)
            points.drop(1).forEach { lineTo(it.x, it.y) }
        }
        drawPath(path, color, style = Stroke(width = width, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }

    fun DrawScope.drawDot(center: Offset, radius: Float, color: Color) {
        drawCircle(color, radius, center)
        drawCircle(outline, radius, center, style = Stroke(width = radius * 0.45f))
    }

    /** A shopping bag filling `rect`: a tall body, with a handle rising out from behind it. */
    fun DrawScope.drawBag(rect: Rect, body: Color, handle: Color) {
        val outlineWidth = rect.width * 0.045f
        val band = rect.width * 0.11f
        val handleRect = Rect(
            Offset(rect.left + rect.width * 0.2f, rect.top + band / 2f),
            androidx.compose.ui.geometry.Size(rect.width * 0.6f, rect.height * 0.5f)
        )
        drawRoundRect(
            handle, handleRect.topLeft, handleRect.size, CornerRadius(rect.width * 0.2f),
            style = Stroke(width = band)
        )
        val bodyRect = Rect(
            Offset(rect.left + outlineWidth / 2f, rect.top + rect.height * 0.22f),
            androidx.compose.ui.geometry.Size(rect.width - outlineWidth, rect.height * 0.78f - outlineWidth / 2f)
        )
        val bag = Path().apply { addRoundRect(RoundRect(bodyRect, CornerRadius(rect.width * 0.13f))) }
        drawPath(bag, Brush.verticalGradient(listOf(body, handle), bodyRect.top, bodyRect.bottom))
        drawPath(bag, outline, style = Stroke(width = outlineWidth, join = StrokeJoin.Round))
    }
}
