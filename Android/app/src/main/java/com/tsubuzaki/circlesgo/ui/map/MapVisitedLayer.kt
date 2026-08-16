package com.tsubuzaki.circlesgo.ui.map

import android.graphics.RectF
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.data.local.VisitEntryCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.database.types.LayoutType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Draws a checkmark over each visited circle's space, mirroring the iOS
 * MapVisitedLayer.
 */
@Composable
fun MapVisitedLayer(
    layouts: Map<LayoutCatalogMapping, List<Int>>,
    visits: List<VisitEntryCache.VisitEntry>,
    eventNumber: Int,
    spaceSize: Int,
    canvasWidth: Dp,
    canvasHeight: Dp,
    database: CatalogDatabase
) {
    var visitedRects by remember { mutableStateOf<List<RectF>>(emptyList()) }

    LaunchedEffect(layouts, visits, eventNumber) {
        val circleIDs = visits
            .filter { it.eventNumber == eventNumber }
            .map { it.circleID }
        if (layouts.isEmpty() || circleIDs.isEmpty()) {
            visitedRects = emptyList()
            return@LaunchedEffect
        }

        withContext(Dispatchers.IO) {
            val fetcher = DataFetcher(database.getTextDatabase())
            val visitedWCIDs = fetcher.webCatalogIDs(circleIDs).toSet()

            val allWCIDs = layouts.values.flatten().toSet().toList()
            val suffixes = fetcher.spaceNumberSuffixes(allWCIDs)

            val result = mutableListOf<RectF>()
            for ((layout, ids) in layouts) {
                val sortedIDs = ids.sortedBy { suffixes[it] ?: 0 }
                val orderedIDs = when (layout.layoutType) {
                    LayoutType.A_ON_BOTTOM, LayoutType.A_ON_RIGHT -> sortedIDs.reversed()
                    else -> sortedIDs
                }
                val count = orderedIDs.size
                if (count == 0) continue
                for ((index, id) in orderedIDs.withIndex()) {
                    if (visitedWCIDs.contains(id)) {
                        result.add(getGenericRect(layout, index, count, spaceSize))
                    }
                }
            }
            visitedRects = result
        }
    }

    Canvas(
        modifier = Modifier
            .width(canvasWidth)
            .height(canvasHeight)
    ) {
        val path = Path()
        for (rect in visitedRects) {
            // Center a square within the rect for the checkmark
            val left = rect.left.dp.toPx()
            val top = rect.top.dp.toPx()
            val width = rect.width().dp.toPx()
            val height = rect.height().dp.toPx()
            val side = minOf(width, height)
            val x = left + (width - side) / 2f
            val y = top + (height - side) / 2f

            path.moveTo(x + side * 0.20f, y + side * 0.50f)
            path.lineTo(x + side * 0.45f, y + side * 0.80f)
            path.lineTo(x + side * 0.80f, y + side * 0.20f)
        }
        drawPath(
            path = path,
            color = Color.Black.copy(alpha = 0.6f),
            style = Stroke(
                width = 3.dp.toPx() / 2f + 2f,
                cap = StrokeCap.Round,
                join = StrokeJoin.Round
            )
        )
        drawPath(
            path = path,
            color = Color.White,
            style = Stroke(
                width = 3.dp.toPx() / 2f,
                cap = StrokeCap.Round,
                join = StrokeJoin.Round
            )
        )
    }
}
