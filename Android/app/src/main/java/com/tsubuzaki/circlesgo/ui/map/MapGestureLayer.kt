package com.tsubuzaki.circlesgo.ui.map

import android.graphics.PointF
import android.graphics.RectF
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.database.types.LayoutType
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.PopoverData

@Composable
fun MapGestureLayer(
    layouts: Map<LayoutCatalogMapping, List<Int>>,
    spaceSize: Int,
    canvasWidth: Dp,
    canvasHeight: Dp,
    popoverData: PopoverData?,
    mapper: Mapper,
    zoomScale: Float,
    onZoomChange: (Float) -> Unit,
    scrollToPosition: PointF?,
    onScrollCompleted: () -> Unit,
    popoverContent: @Composable (Offset, Float) -> Unit = { _, _ -> },
    content: @Composable () -> Unit
) {
    var currentZoom by remember { mutableFloatStateOf(zoomScale) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    var viewportSize by remember { mutableStateOf(IntSize.Zero) }

    LaunchedEffect(zoomScale) {
        currentZoom = zoomScale
    }

    val density = LocalDensity.current
    fun getCoercedOffset(proposedOffset: Offset): Offset {
        val zoomedWidth = with(density) { (canvasWidth * currentZoom).toPx() }
        val zoomedHeight = with(density) { (canvasHeight * currentZoom).toPx() }

        val minX = (viewportSize.width - zoomedWidth).coerceAtMost(0f)
        val minY = (viewportSize.height - zoomedHeight).coerceAtMost(0f)

        return Offset(proposedOffset.x.coerceIn(minX, 0f), proposedOffset.y.coerceIn(minY, 0f))
    }

    LaunchedEffect(scrollToPosition, currentZoom, viewportSize, canvasWidth, canvasHeight) {
        scrollToPosition?.let {
            if (viewportSize != IntSize.Zero && canvasWidth.value > 0 && canvasHeight.value > 0) {
                val newOffset = Offset(
                    x = (viewportSize.width / 2) - (it.x * currentZoom),
                    y = (viewportSize.height / 2) - (it.y * currentZoom)
                )
                offset = getCoercedOffset(newOffset)
                onScrollCompleted()
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .onSizeChanged { viewportSize = it }
            .pointerInput(Unit) {
                detectTransformGestures { centroid, pan, zoom, _ ->
                    val oldZoom = currentZoom
                    val newZoom = (currentZoom * zoom).coerceIn(0.5f, 3.0f)
                    onZoomChange(newZoom)
                    currentZoom = newZoom

                    val gestureZoom = newZoom / oldZoom
                    val newOffset =
                        offset * gestureZoom + centroid * (1 - gestureZoom) + pan

                    offset = getCoercedOffset(newOffset)
                }
            }
            .pointerInput(layouts, density, currentZoom, offset) {
                detectTapGestures { tapOffset ->
                    val mapX = (tapOffset.x - offset.x) / currentZoom
                    val mapY = (tapOffset.y - offset.y) / currentZoom

                    val mapXDp = mapX / density.density
                    val mapYDp = mapY / density.density

                    val x = mapXDp.toInt()
                    val y = mapYDp.toInt()

                    for ((layout, webCatalogIDs) in layouts) {
                        val xMin = layout.positionX
                        val xMax = layout.positionX + spaceSize
                        val yMin = layout.positionY
                        val yMax = layout.positionY + spaceSize

                        if (x in xMin until xMax && y in yMin until yMax) {
                            val newPopover = PopoverData(
                                layout = layout,
                                webCatalogIDs = webCatalogIDs,
                                reversed = layout.layoutType == LayoutType.A_ON_BOTTOM ||
                                        layout.layoutType == LayoutType.A_ON_RIGHT,
                                sourceRect = RectF(
                                    xMin.toFloat(), yMin.toFloat(),
                                    xMax.toFloat(), yMax.toFloat()
                                )
                            )
                            if (popoverData?.id == newPopover.id) {
                                mapper.setPopoverData(null)
                            } else {
                                mapper.setPopoverData(newPopover)
                            }
                            return@detectTapGestures
                        }
                    }
                    // Tapped outside any layout block
                    mapper.setPopoverData(null)
                }
            }
    ) {
        Box(
            modifier = Modifier
                .graphicsLayer(
                    scaleX = currentZoom,
                    scaleY = currentZoom,
                    translationX = offset.x,
                    translationY = offset.y,
                    transformOrigin = TransformOrigin(0f, 0f)
                )
        ) {
            content()
        }
    }

    popoverContent(offset, currentZoom)
}
