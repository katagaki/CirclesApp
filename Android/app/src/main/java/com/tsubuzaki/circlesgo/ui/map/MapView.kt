package com.tsubuzaki.circlesgo.ui.map

import android.graphics.Bitmap
import android.graphics.RectF
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.state.ComiketHall
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.MapAutoScrollType
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.UserSelections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun MapView(
    database: CatalogDatabase,
    mapper: Mapper,
    selections: UserSelections,
    favorites: FavoritesState,
    useHighResolutionMaps: Boolean = true,
    showGenreOverlay: Boolean = false,
    scrollType: MapAutoScrollType = MapAutoScrollType.NONE,
    onCircleTapped: (ComiketCircle) -> Unit = {}
) {
    val selectedDate by selections.date.collectAsState()
    val selectedMap by selections.map.collectAsState()
    val layouts by mapper.layouts.collectAsState()
    val popoverData by mapper.popoverData.collectAsState()
    val highlightTarget by mapper.highlightTarget.collectAsState()
    val popoverPosition by mapper.popoverPosition.collectAsState()
    val scrollToPosition by mapper.scrollToPosition.collectAsState()
    val canvasWidth by mapper.canvasWidth.collectAsState()
    val canvasHeight by mapper.canvasHeight.collectAsState()
    val favoriteItems by favorites.wcIDMappedItems.collectAsState()
    val commonImagesLoadCount by database.commonImagesLoadCount.collectAsState()

    var mapImage by remember { mutableStateOf<Bitmap?>(null) }
    var genreImage by remember { mutableStateOf<Bitmap?>(null) }
    var zoomScale by remember { mutableFloatStateOf(1.0f) }

    val spaceSize = if (useHighResolutionMaps) 40 else 20

    // Reload map image when selection changes or when common images finish loading
    LaunchedEffect(selectedDate, selectedMap, commonImagesLoadCount) {
        val date = selectedDate
        val map = selectedMap
        if (date != null && map != null) {
            val hall = ComiketHall.fromValue(map.filename)
            if (hall != null) {
                mapImage = database.mapImage(hall.value, date.id, useHighResolutionMaps)
                genreImage = database.genreImage(hall.value, date.id, useHighResolutionMaps)
            } else {
                mapImage = null
                genreImage = null
            }
        } else {
            mapImage = null
            genreImage = null
        }
    }

    // Update canvas size when map image changes
    LaunchedEffect(mapImage) {
        mapImage?.let {
            mapper.setCanvasSize(it.width.dp, it.height.dp)
        }
    }

    // Reload layouts when map/date changes
    LaunchedEffect(selectedDate, selectedMap, mapImage) {
        val map = selectedMap
        val date = selectedDate
        if (map != null && date != null && mapImage != null) {
            withContext(Dispatchers.IO) {
                val fetcher = DataFetcher(database.getTextDatabase())
                val mappings = fetcher.layoutMappings(map.id, useHighResolutionMaps)
                val layoutWebCatalogIDMappings: Map<LayoutCatalogMapping, List<Int>> =
                    if (mappings.isNotEmpty()) {
                        fetcher.layoutCatalogMappingToWebCatalogIDs(mappings, date.id)
                    } else {
                        emptyMap()
                    }
                mapper.setLayouts(layoutWebCatalogIDMappings)
            }
        } else {
            mapper.removeAllLayouts()
        }
    }

    // Handle highlight target
    LaunchedEffect(highlightTarget) {
        val target = highlightTarget
        if (target != null) {
            val success = mapper.highlightCircle(spaceSize)
            if (!success) {
                // Try to switch to the correct map/date
                withContext(Dispatchers.IO) {
                    val fetcher = DataFetcher(database.getTextDatabase())
                    val mapID = fetcher.mapID(target.blockID)
                    if (mapID != null) {
                        val maps = database.maps()
                        val dates = database.dates()
                        val newMap = maps.firstOrNull { it.id == mapID }
                        val newDate = dates.firstOrNull { it.id == target.day }
                        if (newMap != null && newDate != null) {
                            if (selectedMap?.id != newMap.id || selectedDate?.id != newDate.id) {
                                selections.setMap(newMap)
                                selections.setDate(newDate)
                                return@withContext
                            }
                        }
                    }
                }
                mapper.setHighlightTarget(null)
            }
        }
    }

    // Retry highlight after layouts reload
    LaunchedEffect(layouts) {
        if (highlightTarget != null) {
            mapper.highlightCircle(spaceSize)
        }
    }

    // Auto-scroll to popover
    LaunchedEffect(popoverPosition) {
        if (scrollType == MapAutoScrollType.POPOVER) {
            popoverPosition?.let { mapper.setScrollToPosition(it) }
        }
    }

    val currentMapImage = mapImage
    if (currentMapImage != null) {
        Box(
            modifier = Modifier
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
                .fillMaxSize(),
        ) {
            MapGestureLayer(
                layouts = layouts,
                spaceSize = spaceSize,
                canvasWidth = canvasWidth,
                canvasHeight = canvasHeight,
                popoverData = popoverData,
                mapper = mapper,
                zoomScale = zoomScale,
                onZoomChange = { zoomScale = it },
                scrollToPosition = scrollToPosition,
                onScrollCompleted = { mapper.clearScrollToPosition() },
                popoverContent = { offset, currentZoom, viewportSize ->
                    val density = androidx.compose.ui.platform.LocalDensity.current
                    popoverData?.let { data ->
                        // Project source rect from map coordinates to screen coordinates
                        // sourceRect is in Dp (from MapGestureLayer).
                        // offset is in Pixels.
                        // We need the result in Dp for MapPopoverLayer.
                        val dx = with(density) { offset.x.toDp().value }
                        val dy = with(density) { offset.y.toDp().value }

                        val originalRect = data.sourceRect
                        val projectedRect = RectF(
                            originalRect.left * currentZoom + dx,
                            originalRect.top * currentZoom + dy,
                            originalRect.right * currentZoom + dx,
                            originalRect.bottom * currentZoom + dy
                        )

                        MapPopoverLayer(
                            popoverData = data.copy(sourceRect = projectedRect),
                            zoomScale = 1.0f, // Use 1.0 scale to prevent scaling
                            canvasWidth = viewportSize.width,
                            canvasHeight = viewportSize.height,
                            mapper = mapper,
                            database = database,
                            favorites = favorites,
                            onCircleTapped = onCircleTapped
                        )
                    }
                }
            ) {
                Box {
                    // Layer 1: Base map image
                    MapImageLayer(
                        bitmap = currentMapImage,
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight
                    )

                    // Layer 2: Favorites overlay
                    MapFavoritesLayer(
                        layouts = layouts,
                        favoriteItems = favoriteItems ?: emptyMap(),
                        spaceSize = spaceSize,
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight,
                        database = database
                    )

                    // Layer 3: Genre overlay
                    if (showGenreOverlay) {
                        genreImage?.let { genre ->
                            MapImageLayer(
                                bitmap = genre,
                                canvasWidth = canvasWidth,
                                canvasHeight = canvasHeight
                            )
                        }
                    }

                    // Layer 4: Layout interaction layer
                    MapLayoutLayer(
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight,
                        popoverData = popoverData
                    )
                }
            }
        }
    } else {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(stringResource(R.string.no_map_selected))
        }
    }
}
