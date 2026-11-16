package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.state.Navigator

private val popoverWidth = 260.dp
private val edgePadding = 8.dp

/**
 * The popover for a long-pressed spot, or a tapped closure, anchored where it was pressed
 * the way a circle's popover is. `offset` and `zoom` place the map inside the viewport.
 */
@Composable
fun MapRouteHoldLayer(navigator: Navigator, spaceSize: Int, offset: Offset, zoom: Float, viewport: DpSize) {
    val anchor = navigator.pendingPoint ?: navigator.selectedClosure?.point ?: return
    val density = LocalDensity.current
    var heightPx by remember { mutableIntStateOf(0) }
    val scale = (spaceSize / Navigator.PLANNING_SPACE_SIZE).toFloat()
    val offsetX = with(density) { offset.x.toDp() }
    val offsetY = with(density) { offset.y.toDp() }
    val anchorX = (anchor.x.toFloat() * scale * zoom).dp + offsetX
    val anchorY = (anchor.y.toFloat() * scale * zoom).dp + offsetY
    val half = (spaceSize * zoom / 2f).dp
    val height = with(density) { heightPx.toDp() }
    val fitsBelow = anchorY + half + height + edgePadding <= viewport.height
    val top = if (fitsBelow) anchorY + half + edgePadding else anchorY - half - edgePadding - height
    val left = (anchorX - popoverWidth / 2)
        .coerceIn(edgePadding, maxOf(edgePadding, viewport.width - popoverWidth - edgePadding))

    Box(modifier = Modifier.offset(x = left, y = top.coerceAtLeast(edgePadding))) {
        Surface(
            modifier = Modifier.width(popoverWidth).onSizeChanged { heightPx = it.height },
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.surfaceContainerHigh,
            shadowElevation = 8.dp
        ) {
            Box(modifier = Modifier.padding(16.dp)) {
                MapRouteHoldPopover(navigator)
            }
        }
    }
}
