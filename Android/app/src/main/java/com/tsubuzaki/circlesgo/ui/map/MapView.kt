package com.tsubuzaki.circlesgo.ui.map

import android.graphics.Bitmap
import android.graphics.PointF
import android.graphics.RectF
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.database.tables.LayoutCatalogMapping
import com.tsubuzaki.circlesgo.state.ComiketHall
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.MapAutoScrollType
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Navigator
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.state.VisitsState
import com.tsubuzaki.circlesgo.ui.shared.LocalNavigator
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
    visitsState: VisitsState? = null,
    events: Events? = null,
    topInset: Dp = 0.dp,
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
    val darkenMapInDarkMode by selections.darkenMapInDarkMode.collectAsState()

    val persistedZoom by selections.mapZoomLevel.collectAsState()
    val navigator = LocalNavigator.current

    var mapImage by remember { mutableStateOf<Bitmap?>(null) }
    var genreImage by remember { mutableStateOf<Bitmap?>(null) }
    var zoomScale by remember { mutableFloatStateOf(persistedZoom) }

    val spaceSize = if (useHighResolutionMaps) 40 else 20

    LaunchedEffect(selectedDate, selectedMap, commonImagesLoadCount, useHighResolutionMaps) {
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

    LaunchedEffect(selectedDate, selectedMap) {
        mapper.setPopoverData(null)
        mapper.setPopoverPosition(null)
    }

    // A route only makes sense on the map it was planned on, so changing the map ends it
    // and drops its closures. The first map shown after launch is not a change.
    var routeMapKey by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(selectedDate, selectedMap) {
        val map = selectedMap ?: return@LaunchedEffect
        val date = selectedDate ?: return@LaunchedEffect
        val key = "${date.id}-${map.id}"
        if (routeMapKey == key) return@LaunchedEffect
        if (routeMapKey != null && navigator != null) {
            if (navigator.isActive) navigator.end()
            navigator.clearClosures()
        }
        routeMapKey = key
        navigator?.loadHalls(map.id, ComiketHall.fromValue(map.filename), date.id)
    }

    LaunchedEffect(layouts) {
        val map = selectedMap ?: return@LaunchedEffect
        val date = selectedDate ?: return@LaunchedEffect
        val hall = ComiketHall.fromValue(map.filename) ?: return@LaunchedEffect
        val eventNumber = events?.activeEventNumber ?: return@LaunchedEffect
        navigator?.resume(eventNumber, map.id, map.name, hall, date.id, layouts)
    }

    val currentStep = navigator?.currentStep
    LaunchedEffect(currentStep) {
        val first = currentStep?.path?.firstOrNull() ?: return@LaunchedEffect
        val last = currentStep.path.last()
        val scale = (spaceSize / Navigator.PLANNING_SPACE_SIZE).toFloat()
        mapper.setScrollToPosition(
            PointF(((first.x + last.x) / 2.0).toFloat() * scale, ((first.y + last.y) / 2.0).toFloat() * scale)
        )
    }

    LaunchedEffect(mapImage) {
        mapImage?.let {
            mapper.setCanvasSize(it.width.dp, it.height.dp)
        }
    }

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

    LaunchedEffect(highlightTarget) {
        val target = highlightTarget
        if (target != null) {
            val success = mapper.highlightCircle(spaceSize)
            if (!success) {
                val isSwitchingMap = withContext(Dispatchers.IO) {
                    val fetcher = DataFetcher(database.getTextDatabase())
                    val mapID = fetcher.mapID(target.blockID)
                    if (mapID != null) {
                        val maps = database.maps()
                        val dates = database.dates()
                        val newMap = maps.firstOrNull { it.id == mapID }
                        val newDate = dates.firstOrNull { it.id == target.day }
                        if (newMap != null && newDate != null &&
                            (selectedMap?.id != newMap.id || selectedDate?.id != newDate.id)
                        ) {
                            selections.setMap(newMap)
                            selections.setDate(newDate)
                            return@withContext true
                        }
                    }
                    false
                }
                if (!isSwitchingMap) {
                    mapper.setHighlightTarget(null)
                }
            }
        }
    }

    LaunchedEffect(layouts) {
        if (highlightTarget != null) {
            mapper.highlightCircle(spaceSize)
        }
    }

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
                onZoomChange = {
                    zoomScale = it
                    selections.setMapZoomLevel(it)
                },
                scrollToPosition = scrollToPosition,
                onScrollCompleted = { mapper.clearScrollToPosition() },
                topInset = topInset,
                onLongPress = { x, y ->
                    if (navigator != null && (navigator.isActive || favoriteItems != null)) {
                        mapper.setPopoverData(null)
                        navigator.hold(x, y, spaceSize)
                    }
                },
                onTapIntercept = { x, y ->
                    when {
                        navigator == null -> false
                        navigator.selectClosure(x, y, spaceSize) -> true
                        navigator.pendingPoint != null || navigator.selectedClosureID != null -> {
                            navigator.cancelHold()
                            true
                        }
                        else -> false
                    }
                },
                popoverContent = { offset, currentZoom, viewportSize ->
                    if (navigator != null) {
                        MapRouteHoldLayer(navigator, spaceSize, offset, currentZoom, viewportSize)
                    }
                    val density = androidx.compose.ui.platform.LocalDensity.current
                    popoverData?.let { data ->
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
                            zoomScale = 1.0f,
                            canvasWidth = viewportSize.width,
                            canvasHeight = viewportSize.height,
                            mapper = mapper,
                            database = database,
                            favorites = favorites,
                            selections = selections,
                            onCircleTapped = onCircleTapped
                        )
                    }
                }
            ) {
                Box {
                    MapImageLayer(
                        bitmap = currentMapImage,
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight,
                        darkenInDarkMode = darkenMapInDarkMode
                    )

                    MapFavoritesLayer(
                        layouts = layouts,
                        favoriteItems = favoriteItems ?: emptyMap(),
                        spaceSize = spaceSize,
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight,
                        database = database
                    )

                    if (showGenreOverlay) {
                        genreImage?.let { genre ->
                            MapImageLayer(
                                bitmap = genre,
                                canvasWidth = canvasWidth,
                                canvasHeight = canvasHeight,
                                darkenInDarkMode = darkenMapInDarkMode
                            )
                        }
                    }

                    MapFilterLayer(
                        layouts = layouts,
                        selections = selections,
                        darkenInDarkMode = darkenMapInDarkMode,
                        spaceSize = spaceSize,
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight,
                        database = database
                    )

                    if (visitsState != null && events != null) {
                        val visits by visitsState.visits.collectAsState()
                        MapVisitedLayer(
                            layouts = layouts,
                            visits = visits,
                            favoriteItems = favoriteItems ?: emptyMap(),
                            eventNumber = events.activeEventNumber,
                            spaceSize = spaceSize,
                            canvasWidth = canvasWidth,
                            canvasHeight = canvasHeight,
                            database = database,
                            darkenInDarkMode = darkenMapInDarkMode,
                            excludedWebCatalogIDs = navigator?.route?.stops?.map { it.id }?.toSet()
                                ?: emptySet()
                        )
                    }

                    if (navigator != null) {
                        MapRouteLayer(navigator, spaceSize, canvasWidth, canvasHeight)
                    }

                    MapHighlightLayer(
                        mapper = mapper,
                        canvasWidth = canvasWidth,
                        canvasHeight = canvasHeight
                    )

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
