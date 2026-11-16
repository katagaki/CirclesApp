package com.tsubuzaki.circlesgo.ui.route

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Block
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.vector.VectorPainter
import androidx.compose.ui.graphics.vector.rememberVectorPainter
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer

private const val HERO_WIDTH = 100f
private const val HERO_HEIGHT = 62f
private const val CELL = 2.6f
private val islandColumns = listOf(13f, 26f, 39f, 60f, 73f)
private val letters = listOf("Ｆ", "Ｅ", "Ｄ", "Ｃ", "Ｂ")
private const val UPPER_TOP = 14f
private const val LOWER_TOP = 39f
private const val ROWS = 6

private val route = listOf(
    Offset(3f, 50.5f), Offset(8f, 50.5f), Offset(8f, 34.3f), Offset(22.1f, 34.3f), Offset(22.1f, 10.3f),
    Offset(52.1f, 10.3f), Offset(52.1f, 57.3f), Offset(81f, 57.3f), Offset(81f, 45f)
)
private val stops = listOf(Offset(22.1f, 21f), Offset(52.1f, 47f), Offset(81f, 45f))
private val closure = Offset(35.1f, 34.3f)
private val letterColor = Color(0.49f, 0.72f, 0.3f)

/**
 * A small hall drawn the way the catalog draws one: islands of numbered spaces split by a
 * cross aisle with green block letters, wall circles along the wall, and the route
 * walking in from the door, around a closed aisle, to three favourites.
 */
@Composable
fun RouteOnboardingHero(modifier: Modifier = Modifier) {
    val progress = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        progress.animateTo(1f, tween(durationMillis = 3000, easing = FastOutSlowInEasing))
    }
    val accent = MaterialTheme.colorScheme.primary
    val line = MaterialTheme.colorScheme.onSurface
    val space = MaterialTheme.colorScheme.surfaceContainerHighest
    val wall = MaterialTheme.colorScheme.outline
    val door = MaterialTheme.colorScheme.outlineVariant
    val ink = MaterialTheme.colorScheme.onSurface
    val textMeasurer = rememberTextMeasurer()
    val walk = rememberVectorPainter(Icons.AutoMirrored.Filled.DirectionsWalk)
    val block = rememberVectorPainter(Icons.Filled.Block)

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(HERO_WIDTH / HERO_HEIGHT)
            .clearAndSetSemantics { }
    ) {
        val scale = size.width / HERO_WIDTH
        fun at(unit: Offset) = Offset(unit.x * scale, unit.y * scale)

        drawRect(door, Offset(0f, 22f * scale), Size(2.4f * scale, 12f * scale))
        val wallPath = Path().apply {
            listOf(Offset(3f, 46f), Offset(3f, 3f), Offset(97f, 3f), Offset(97f, 60f), Offset(3f, 60f), Offset(3f, 55f))
                .map { at(it) }
                .forEachIndexed { index, point -> if (index == 0) moveTo(point.x, point.y) else lineTo(point.x, point.y) }
        }
        drawPath(wallPath, wall, style = Stroke(width = 0.9f * scale))
        val thin = 0.18f * scale
        fun spaceAt(x: Float, y: Float) {
            drawRect(space, at(Offset(x, y)), Size(CELL * scale, CELL * scale))
            drawRect(line, at(Offset(x, y)), Size(CELL * scale, CELL * scale), style = Stroke(width = thin))
        }
        for (start in listOf(12f, 62f)) {
            for (index in 0 until 8) spaceAt(start + index * CELL, 3.9f)
        }
        for (column in islandColumns) {
            for (top in listOf(UPPER_TOP, LOWER_TOP)) {
                for (row in 0 until ROWS) {
                    for (side in 0 until 2) spaceAt(column + side * CELL, top + row * CELL)
                }
            }
        }

        val fullPath = Path().apply {
            route.map { at(it) }.forEachIndexed { index, point ->
                if (index == 0) moveTo(point.x, point.y) else lineTo(point.x, point.y)
            }
        }
        val measure = PathMeasure().apply { setPath(fullPath, false) }
        val trimmed = Path()
        measure.getSegment(0f, measure.length * progress.value, trimmed, true)
        drawPath(
            trimmed, accent,
            style = Stroke(width = 1.6f * scale, cap = StrokeCap.Round, join = StrokeJoin.Round)
        )

        letters.forEachIndexed { index, letter ->
            drawCentered(textMeasurer, letter, at(Offset(islandColumns[index] + CELL, 34.3f)), 4.2f * scale, letterColor, FontWeight.Black)
        }

        val closurePoint = at(closure)
        drawRoundRect(
            Color.Red, Offset(closurePoint.x - 0.5f * scale, closurePoint.y - 3f * scale),
            Size(1f * scale, 6f * scale), CornerRadius(0.5f * scale)
        )
        drawBadge(at(Offset(closure.x, closure.y - 4.2f)), scale, ink)
        drawIcon(block, at(Offset(closure.x, closure.y - 4.2f)), 2.6f * scale)

        stops.forEachIndexed { index, stop ->
            val center = at(stop)
            drawBadge(center, scale, accent)
            drawCentered(textMeasurer, "${index + 1}", center, 2.6f * scale, Color.White, FontWeight.Bold)
        }
        drawBadge(at(route[0]), scale, accent)
        drawIcon(walk, at(route[0]), 2.6f * scale)
    }
}

private fun DrawScope.drawBadge(center: Offset, scale: Float, fill: Color) {
    drawCircle(Color.Black.copy(alpha = 0.2f), 2.4f * scale, center.copy(y = center.y + 0.2f * scale))
    drawCircle(fill, 2.2f * scale, center)
    drawCircle(Color.White, 2.2f * scale, center, style = Stroke(width = 0.5f * scale))
}

private fun DrawScope.drawIcon(painter: VectorPainter, center: Offset, side: Float) {
    translate(center.x - side / 2f, center.y - side / 2f) {
        with(painter) { draw(Size(side, side), colorFilter = ColorFilter.tint(Color.White)) }
    }
}

private fun DrawScope.drawCentered(
    measurer: TextMeasurer, text: String, center: Offset, sizePx: Float, color: Color, weight: FontWeight
) {
    val layout = measurer.measure(
        text, TextStyle(color = color, fontSize = sizePx.toSp(), fontWeight = weight)
    )
    drawText(layout, topLeft = Offset(center.x - layout.size.width / 2f, center.y - layout.size.height / 2f))
}
