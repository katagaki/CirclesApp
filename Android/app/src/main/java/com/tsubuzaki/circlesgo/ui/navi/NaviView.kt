package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuyStatus
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.CircleDisplayMode
import com.tsubuzaki.circlesgo.state.ComiketHall
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Navigator
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.state.VisitsState
import com.tsubuzaki.circlesgo.ui.catalog.CircleGrid
import com.tsubuzaki.circlesgo.ui.catalog.CircleList
import com.tsubuzaki.circlesgo.ui.shared.LocalSharedBuys
import com.tsubuzaki.circlesgo.ui.unified.UnifiedRouteNoStopsCard
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import androidx.compose.runtime.rememberCoroutineScope

@Composable
fun NaviView(
    navigator: Navigator,
    database: CatalogDatabase,
    selections: UserSelections,
    favorites: FavoritesState,
    mapper: Mapper,
    unifier: Unifier,
    events: Events,
    buysCache: BuysCache,
    visitsState: VisitsState
) {
    val scope = rememberCoroutineScope()
    val selectedMap by selections.map.collectAsState()
    val selectedDate by selections.date.collectAsState()
    val layouts by mapper.layouts.collectAsState()
    val favoriteItems by favorites.wcIDMappedItems.collectAsState()
    val visits by visitsState.visits.collectAsState()
    val buysVersion by buysCache.version.collectAsState()
    val displayMode by selections.displayMode.collectAsState()
    val gridSize by selections.gridSize.collectAsState()
    val listSize by selections.listSize.collectAsState()
    val sharedBuys = LocalSharedBuys.current?.takeIf { it.isActive }

    var searchTerm by remember { mutableStateOf("") }
    var results by remember { mutableStateOf<List<ComiketCircle>?>(null) }
    var pendingDestination by remember { mutableStateOf<ComiketCircle?>(null) }
    var ownBuysOnMap by remember { mutableStateOf<List<Int>>(emptyList()) }
    var sharedBuysOnMap by remember { mutableStateOf<List<Int>>(emptyList()) }

    val isMapReady = selectedMap != null && selectedDate != null
    val eventNumber = events.activeEventNumber

    fun favoriteColors(): Map<Int, WebCatalogColor> =
        favoriteItems.orEmpty().mapValues { WebCatalogColor.fromValue(it.value.favorite.color) }

    fun startRoute(colors: Map<Int, WebCatalogColor>, colorPriority: List<WebCatalogColor>?, includesVisited: Boolean) {
        val map = selectedMap ?: return
        val date = selectedDate ?: return
        val hall = ComiketHall.fromValue(map.filename) ?: return
        navigator.start(
            Navigator.GuideContext(
                eventNumber = eventNumber,
                mapID = map.id,
                mapName = map.name,
                hall = hall,
                day = date.id,
                layouts = mapper.layouts.value,
                favoriteColors = colors,
                visitedCircleIDs = if (includesVisited) emptyList() else visits
                    .filter { it.eventNumber == eventNumber }
                    .map { it.circleID },
                colorPriority = colorPriority
            )
        )
    }

    fun routeThrough(webCatalogIDs: List<Int>) {
        if (webCatalogIDs.isEmpty()) return
        val colors = favoriteColors()
        startRoute(webCatalogIDs.associateWith { colors[it] ?: WebCatalogColor.UNCOLORED }, null, true)
    }

    fun routeDirectly(webCatalogID: Int) {
        val color = favoriteColors()[webCatalogID] ?: WebCatalogColor.UNCOLORED
        startRoute(mapOf(webCatalogID to color), null, true)
    }

    /** How many favourites of each colour sit on the open map. */
    fun colorCounts(): Map<WebCatalogColor, Int> {
        val colors = favoriteColors()
        val counts = mutableMapOf<WebCatalogColor, Int>()
        for (webCatalogIDs in layouts.values) {
            for (webCatalogID in webCatalogIDs) {
                colors[webCatalogID]?.let { counts[it] = (counts[it] ?: 0) + 1 }
            }
        }
        return counts
    }

    fun proceed(mode: Navigator.Mode) {
        when (mode) {
            Navigator.Mode.EFFICIENT -> startRoute(favoriteColors(), null, false)
            Navigator.Mode.PRIORITIZED -> navigator.openPriority(colorCounts()) { priority ->
                startRoute(favoriteColors(), priority, false)
            }
        }
    }

    fun startDirections(circle: ComiketCircle) {
        val webCatalogID = circle.extendedInformation?.webCatalogID ?: return
        searchTerm = ""
        results = null
        if (layouts.values.any { webCatalogID in it }) {
            routeDirectly(webCatalogID)
            return
        }
        pendingDestination = circle
        scope.launch {
            val fetcher = DataFetcher(database.getTextDatabase())
            val mapID = fetcher.mapID(circle.blockID)
            val map = withContext(Dispatchers.IO) { database.maps().firstOrNull { it.id == mapID } }
            val date = withContext(Dispatchers.IO) { database.dates().firstOrNull { it.id == circle.day } }
            if (map == null || date == null) {
                pendingDestination = null
                return@launch
            }
            selections.setMap(map)
            selections.setDate(date)
        }
    }

    LaunchedEffect(layouts) {
        val destination = pendingDestination ?: return@LaunchedEffect
        val webCatalogID = destination.extendedInformation?.webCatalogID ?: return@LaunchedEffect
        if (layouts.values.none { webCatalogID in it }) return@LaunchedEffect
        pendingDestination = null
        routeDirectly(webCatalogID)
    }

    LaunchedEffect(navigator.isActive) {
        if (navigator.isActive) {
            searchTerm = ""
            results = null
        }
    }

    LaunchedEffect(searchTerm) {
        if (searchTerm.isEmpty()) {
            results = null
            return@LaunchedEffect
        }
        delay(250)
        results = withContext(Dispatchers.IO) {
            CatalogCache.searchCircles(searchTerm, database)?.let { database.circles(it.take(100)) }
        }
    }

    val sharedItems = sharedBuys?.items
    LaunchedEffect(layouts, buysVersion, eventNumber, sharedItems) {
        val onMap = layouts.values.flatten().toSet()
        val fetcher = DataFetcher(database.getTextDatabase())
        suspend fun onMapIDs(circleIDs: List<Int>): List<Int> =
            if (circleIDs.isEmpty()) emptyList() else fetcher.webCatalogIDs(circleIDs).filter { it in onMap }
        val ownCircleIDs = withContext(Dispatchers.IO) {
            buysCache.entries(eventNumber)
                .filter { entry ->
                    entry.items.any { it.status == BuysCache.STATUS_PENDING && it.name.isNotBlank() }
                }
                .map { it.circleID }
        }
        ownBuysOnMap = onMapIDs(ownCircleIDs)
        sharedBuysOnMap = if (sharedBuys != null && sharedItems != null) {
            onMapIDs(
                sharedItems
                    .filter {
                        it.status == SharedBuyStatus.PENDING &&
                            (it.assignee == null || it.assignee == sharedBuys.actorPid)
                    }
                    .map { it.circleId }
                    .distinct()
            )
        } else {
            emptyList()
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        if (navigator.isActive) {
            NaviActiveRoute(
                navigator, database, favorites, unifier, buysCache, eventNumber,
                modifier = Modifier.weight(1f)
            )
            NaviStepToolbar(navigator)
            return@Column
        }
        NaviSearchField(searchTerm) { searchTerm = it }
        val currentResults = results
        if (currentResults != null) {
            if (currentResults.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        stringResource(R.string.navi_no_results),
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else if (displayMode == CircleDisplayMode.GRID) {
                CircleGrid(
                    circles = currentResults,
                    displayMode = gridSize,
                    database = database,
                    favorites = favorites,
                    onSelect = { startDirections(it) }
                )
            } else {
                CircleList(
                    circles = currentResults,
                    displayMode = listSize,
                    database = database,
                    favorites = favorites,
                    onSelect = { startDirections(it) }
                )
            }
            return@Column
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            if (navigator.isNoStopsAlertPresented) {
                UnifiedRouteNoStopsCard { navigator.dismissNoStops() }
            }
            NaviModesSection(
                isEnabled = isMapReady,
                ownBuysCount = ownBuysOnMap.size,
                sharedBuysCount = if (sharedBuys != null) sharedBuysOnMap.size else null,
                onChoose = { mode -> proceed(mode) },
                onOwnBuys = { routeThrough(ownBuysOnMap) },
                onSharedBuys = { routeThrough(sharedBuysOnMap) }
            )
        }
    }
}
