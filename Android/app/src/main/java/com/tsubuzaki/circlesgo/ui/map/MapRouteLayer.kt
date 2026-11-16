package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.state.Navigator
import com.tsubuzaki.circlesgo.wayfinding.RoutePoint

private val closureRed = Color(0xFFFF3B30)

@Composable
fun MapRouteLayer(navigator: Navigator, spaceSize: Int, canvasWidth: Dp, canvasHeight: Dp) {
    val scale = (spaceSize / Navigator.PLANNING_SPACE_SIZE).toFloat()
    val accent = MaterialTheme.colorScheme.primary
    val passed = MaterialTheme.colorScheme.outline.copy(alpha = 0.45f)
    val ink = MaterialTheme.colorScheme.onSurface
    val route = navigator.route
    val currentStop = navigator.currentStep?.stopIndex ?: 0
    val step = navigator.currentStep
    val closureLines = navigator.closureLines
    val pendingLine = navigator.pendingClosureLine

    Box(modifier = Modifier.size(canvasWidth, canvasHeight)) {
        Canvas(modifier = Modifier.size(canvasWidth, canvasHeight)) {
            val lineWidth = (spaceSize * 0.22f).dp.toPx()
            fun path(points: List<RoutePoint>): Path = Path().apply {
                points.firstOrNull()?.let { moveTo(point(it, scale).x, point(it, scale).y) }
                points.drop(1).forEach { lineTo(point(it, scale).x, point(it, scale).y) }
            }
            fun round(width: Float, effect: PathEffect? = null) =
                Stroke(width = width, cap = StrokeCap.Round, join = StrokeJoin.Round, pathEffect = effect)

            if (route != null) {
                route.legs.forEachIndexed { index, leg ->
                    drawPath(path(leg), if (index < currentStop) passed else accent.copy(alpha = 0.35f), style = round(lineWidth))
                }
                route.legs.getOrNull(currentStop)?.let { leg ->
                    drawPath(path(leg), Color.Black.copy(alpha = 0.15f), style = round(lineWidth * 2.3f))
                    drawPath(path(leg), Color.White, style = round(lineWidth * 1.9f))
                    drawPath(path(leg), accent, style = round(lineWidth * 1.2f))
                }
                if (step != null) {
                    drawPath(
                        path(step.path), Color.White,
                        style = round(
                            lineWidth * 0.45f,
                            PathEffect.dashPathEffect(floatArrayOf(lineWidth * 0.2f, lineWidth * 0.9f))
                        )
                    )
                }
                route.outsidePaths.forEach { walk ->
                    drawPath(
                        path(walk), accent,
                        style = round(
                            lineWidth * 0.9f,
                            PathEffect.dashPathEffect(floatArrayOf(lineWidth * 0.3f, lineWidth * 1.2f))
                        )
                    )
                }
            }
            val closureEffect = PathEffect.dashPathEffect(floatArrayOf(lineWidth * 0.6f, lineWidth * 0.4f))
            closureLines.forEach { line ->
                drawPath(
                    path(listOf(line.from, line.to)), closureRed,
                    style = Stroke(width = lineWidth * 0.3f, cap = StrokeCap.Butt, pathEffect = closureEffect)
                )
            }
            if (pendingLine != null) {
                drawPath(
                    path(listOf(pendingLine.first, pendingLine.second)), ink.copy(alpha = 0.5f),
                    style = Stroke(width = lineWidth * 0.3f, cap = StrokeCap.Butt, pathEffect = closureEffect)
                )
            }
        }
        route?.stops?.forEachIndexed { index, stop ->
            val size = spaceSize.dp * if (index == currentStop) 0.95f else 0.7f
            MapRouteStopBadge(
                number = index + 1,
                phase = when {
                    index < currentStop -> MapRouteStopPhase.DONE
                    index == currentStop -> MapRouteStopPhase.CURRENT
                    else -> MapRouteStopPhase.UPCOMING
                },
                size = size,
                modifier = Modifier.centered(stop.accessPoint, scale, size)
            )
        }
        navigator.activeClosures.forEach { closure ->
            val size = spaceSize.dp * 0.85f
            MapRouteClosureBadge(
                size = size,
                isSelected = navigator.selectedClosureID == closure.id,
                modifier = Modifier.centered(closure.point, scale, size * 1.8f)
            )
        }
        navigator.pendingPoint?.let {
            val size = spaceSize.dp * 0.8f
            MapRouteHoldMarker(size = size, modifier = Modifier.centered(it, scale, size * 1.8f))
        }
        navigator.currentLocation?.let {
            val size = spaceSize.dp * 0.8f
            MapRouteOriginPin(size = size, modifier = Modifier.centered(it, scale, size))
        }
    }
}

private fun DrawScope.point(point: RoutePoint, scale: Float): Offset =
    Offset((point.x.toFloat() * scale).dp.toPx(), (point.y.toFloat() * scale).dp.toPx())

private fun Modifier.centered(point: RoutePoint, scale: Float, size: Dp): Modifier =
    offset(x = (point.x.toFloat() * scale).dp - size / 2, y = (point.y.toFloat() * scale).dp - size / 2)
