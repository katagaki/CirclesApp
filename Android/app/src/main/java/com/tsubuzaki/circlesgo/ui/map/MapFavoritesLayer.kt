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
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.api.catalog.UserFavorites
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.database.types.LayoutType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun MapFavoritesLayer(
    layouts: Map<LayoutCatalogMapping, List<Int>>,
    favoriteItems: Map<Int, UserFavorites.Response.FavoriteItem>,
    spaceSize: Int,
    canvasWidth: Dp,
    canvasHeight: Dp,
    database: CatalogDatabase
) {
    var colorRects by remember { mutableStateOf<Map<WebCatalogColor, List<RectF>>>(emptyMap()) }

    LaunchedEffect(layouts, favoriteItems) {
        if (layouts.isEmpty() || favoriteItems.isEmpty()) {
            colorRects = emptyMap()
            return@LaunchedEffect
        }

        withContext(Dispatchers.IO) {
            val fetcher = DataFetcher(database.getTextDatabase())

            // Build webCatalogID -> layout mapping
            val wcIDToLayout = mutableMapOf<Int, LayoutCatalogMapping>()
            for ((layout, ids) in layouts) {
                for (id in ids) {
                    wcIDToLayout[id] = layout
                }
            }

            // Build layout -> (wcID -> color) mapping
            val layoutFavorites =
                mutableMapOf<LayoutCatalogMapping, MutableMap<Int, WebCatalogColor?>>()
            for ((layout, ids) in layouts) {
                layoutFavorites[layout] =
                    ids.associateWith { null as WebCatalogColor? }.toMutableMap()
            }
            for ((wcID, item) in favoriteItems) {
                val layout = wcIDToLayout[wcID] ?: continue
                layoutFavorites[layout]?.put(wcID, WebCatalogColor.fromValue(item.favorite.color))
            }

            // Get space number suffixes for sorting
            val allWCIDs = layouts.values.flatten().toSet().toList()
            val suffixes = fetcher.spaceNumberSuffixes(allWCIDs)

            val result = mutableMapOf<WebCatalogColor, MutableList<RectF>>()

            for ((layout, mapping) in layoutFavorites) {
                val sortedIDs = mapping.keys.sortedBy { suffixes[it] ?: 0 }
                val orderedIDs = when (layout.layoutType) {
                    LayoutType.A_ON_BOTTOM, LayoutType.A_ON_RIGHT -> sortedIDs.reversed()
                    else -> sortedIDs
                }

                val count = orderedIDs.size
                if (count == 0) continue

                for ((index, id) in orderedIDs.withIndex()) {
                    val color = mapping[id] ?: continue
                    val rect = getGenericRect(layout, index, count, spaceSize)
                    result.getOrPut(color) { mutableListOf() }.add(rect)
                }
            }

            colorRects = result
        }
    }

    Canvas(
        modifier = Modifier
            .width(canvasWidth)
            .height(canvasHeight)
    ) {
        for ((color, rects) in colorRects) {
            val composeColor = color.backgroundColor().copy(alpha = 0.5f)
            for (rect in rects) {
                drawRect(
                    color = composeColor,
                    topLeft = Offset(rect.left.dp.toPx(), rect.top.dp.toPx()),
                    size = Size(rect.width().dp.toPx(), rect.height().dp.toPx())
                )
            }
        }
    }
}

fun getGenericRect(layout: LayoutCatalogMapping, index: Int, total: Int, spaceSize: Int): RectF {
    val castSpaceSize = spaceSize.toFloat()
    val baseX = layout.positionX.toFloat()
    val baseY = layout.positionY.toFloat()
    val idx = index.toFloat()

    return when (layout.layoutType) {
        LayoutType.A_ON_LEFT, LayoutType.A_ON_RIGHT, LayoutType.UNKNOWN -> {
            val rectWidth = castSpaceSize / total.toFloat()
            RectF(
                baseX + idx * rectWidth,
                baseY,
                baseX + idx * rectWidth + rectWidth,
                baseY + castSpaceSize
            )
        }

        LayoutType.A_ON_TOP, LayoutType.A_ON_BOTTOM -> {
            val rectHeight = castSpaceSize / total.toFloat()
            RectF(
                baseX,
                baseY + idx * rectHeight,
                baseX + castSpaceSize,
                baseY + idx * rectHeight + rectHeight
            )
        }
    }
}
