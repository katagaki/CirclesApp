package com.tsubuzaki.circlesgo.ui.route

import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.state.Navigator

private val cellHeight = 72.dp
private val spacing = 12.dp

/**
 * Every favourite colour as a circle. Tapping one includes or leaves it out; long-pressing
 * and dragging one moves it. Included colours are numbered in the order they are visited.
 */
@Composable
fun RoutePriorityView(navigator: Navigator) {
    var order by remember { mutableStateOf<List<WebCatalogColor>>(emptyList()) }
    var included by remember { mutableStateOf<Set<WebCatalogColor>>(emptySet()) }
    var dragging by remember { mutableStateOf<WebCatalogColor?>(null) }
    val counts = navigator.priorityCounts

    LaunchedEffect(Unit) {
        val storedOrder = navigator.storedColorOrder
        val saved = storedOrder.split(",").mapNotNull { it.toIntOrNull() }
            .map { WebCatalogColor.fromValue(it) }
            .filter { it != WebCatalogColor.UNCOLORED }
            .distinct()
        order = saved + WebCatalogColor.assignable.filter { it !in saved }
        included = if (storedOrder.isEmpty()) {
            order.filter { (counts[it] ?: 0) > 0 }.toSet()
        } else {
            val excluded = navigator.storedColorExclusions.split(",").mapNotNull { it.toIntOrNull() }
                .map { WebCatalogColor.fromValue(it) }.toSet()
            order.toSet() - excluded
        }
    }

    val canStart = order.any { it in included && (counts[it] ?: 0) > 0 }
    fun rank(color: WebCatalogColor): Int? =
        order.filter { it in included }.indexOf(color).takeIf { it >= 0 }?.plus(1)

    fun finish(priority: List<WebCatalogColor>?) {
        val request = navigator.priorityRequest
        navigator.closePriority()
        if (priority != null) request?.invoke(priority)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { finish(null) }) {
                Icon(Icons.Filled.Close, contentDescription = stringResource(R.string.cancel))
            }
            Text(
                stringResource(R.string.route_priority_title),
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.weight(1f)
            )
            Button(
                onClick = {
                    navigator.storedColorOrder = order.joinToString(",") { it.value.toString() }
                    navigator.storedColorExclusions = order.filter { it !in included }
                        .joinToString(",") { it.value.toString() }
                    finish(order.filter { it in included })
                },
                enabled = canStart
            ) {
                Text(stringResource(R.string.route_priority_start))
            }
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState(), enabled = dragging == null)
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                stringResource(R.string.route_priority_footer),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            BoxWithConstraints(modifier = Modifier.fillMaxWidth()) {
                val density = LocalDensity.current
                val columns = maxOf(1, ((maxWidth + spacing) / (84.dp + spacing)).toInt())
                val slotWidth = (maxWidth - spacing * (columns - 1)) / columns
                val rows = (order.size + columns - 1) / columns
                fun indexAt(position: Offset): Int {
                    val column = (position.x / with(density) { (slotWidth + spacing).toPx() }).toInt()
                        .coerceIn(0, columns - 1)
                    val row = (position.y / with(density) { (cellHeight + spacing).toPx() }).toInt()
                        .coerceIn(0, rows - 1)
                    return (row * columns + column).coerceIn(0, order.size - 1)
                }
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(cellHeight * rows + spacing * maxOf(rows - 1, 0))
                        .pointerInput(order.size, columns) {
                            detectDragGesturesAfterLongPress(
                                onDragStart = { dragging = order.getOrNull(indexAt(it)) },
                                onDragEnd = { dragging = null },
                                onDragCancel = { dragging = null },
                                onDrag = { change, _ ->
                                    val color = dragging ?: return@detectDragGesturesAfterLongPress
                                    val target = indexAt(change.position)
                                    val from = order.indexOf(color)
                                    if (from >= 0 && target != from) {
                                        order = order.toMutableList().apply {
                                            removeAt(from)
                                            add(target, color)
                                        }
                                    }
                                }
                            )
                        }
                ) {
                    order.forEachIndexed { index, color ->
                        val column = index % columns
                        val row = index / columns
                        Box(
                            modifier = Modifier
                                .padding(
                                    start = (slotWidth + spacing) * column,
                                    top = (cellHeight + spacing) * row
                                )
                                .width(slotWidth)
                                .height(cellHeight)
                                .clickable {
                                    included = if (color in included) included - color else included + color
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            RoutePriorityColorCell(
                                color = color,
                                rank = rank(color),
                                count = counts[color] ?: 0,
                                modifier = Modifier.scale(if (dragging == color) 1.15f else 1f)
                            )
                        }
                    }
                }
            }
        }
    }
}
