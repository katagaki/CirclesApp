package com.tsubuzaki.circlesgo.ui.map

import android.graphics.RectF
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.database.types.LayoutType
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.UserSelections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Dims circle spaces that do not match the active genre/block filters,
 * mirroring the iOS MapFilterLayer.
 */
@Composable
fun MapFilterLayer(
    layouts: Map<LayoutCatalogMapping, List<Int>>,
    selections: UserSelections,
    darkenInDarkMode: Boolean,
    spaceSize: Int,
    canvasWidth: Dp,
    canvasHeight: Dp,
    database: CatalogDatabase
) {
    val selectedGenres by selections.genres.collectAsState()
    val selectedBlocks by selections.blocks.collectAsState()
    val selectedMap by selections.map.collectAsState()
    val selectedDate by selections.date.collectAsState()

    val isFilterActive = selectedGenres.isNotEmpty() || selectedBlocks.isNotEmpty()

    var dimRects by remember { mutableStateOf<List<RectF>>(emptyList()) }

    LaunchedEffect(layouts, selectedGenres, selectedBlocks, selectedMap, selectedDate) {
        if (!isFilterActive || layouts.isEmpty()) {
            dimRects = emptyList()
            return@LaunchedEffect
        }

        withContext(Dispatchers.IO) {
            val fetcher = DataFetcher(database.getTextDatabase())

            val circleIDs = CatalogCache.fetchCircles(
                genreIDs = selectedGenres.map { it.id }.ifEmpty { null },
                mapID = selectedMap?.id,
                blockIDs = selectedBlocks.map { it.id }.ifEmpty { null },
                dayID = selectedDate?.id,
                database = database
            )
            val filteredWCIDs = fetcher.webCatalogIDs(circleIDs).toSet()

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
                    if (!filteredWCIDs.contains(id)) {
                        result.add(getGenericRect(layout, index, count, spaceSize))
                    }
                }
            }
            dimRects = result
        }
    }

    val isDarkMap = isSystemInDarkTheme() && darkenInDarkMode
    val dimColor = if (isDarkMap) {
        Color.Black.copy(alpha = 0.8f)
    } else {
        Color.White.copy(alpha = 0.85f)
    }

    if (isFilterActive) {
        Canvas(
            modifier = Modifier
                .width(canvasWidth)
                .height(canvasHeight)
        ) {
            for (rect in dimRects) {
                drawRect(
                    color = dimColor,
                    topLeft = Offset(rect.left.dp.toPx(), rect.top.dp.toPx()),
                    size = Size(
                        rect.width().dp.toPx() + 1f,
                        rect.height().dp.toPx() + 1f
                    )
                )
            }
        }
    }
}
