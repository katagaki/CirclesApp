package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.CircleDisplayMode
import com.tsubuzaki.circlesgo.state.FavoritesFilters
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.catalog.CircleGrid
import com.tsubuzaki.circlesgo.ui.catalog.CircleList
import com.tsubuzaki.circlesgo.ui.catalog.ColorGroupedCircleGrid
import com.tsubuzaki.circlesgo.ui.catalog.ColorGroupedCircleList
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesView(
    database: CatalogDatabase,
    favorites: FavoritesState,
    selections: UserSelections,
    unifier: Unifier,
    favoritesAPI: FavoritesAPI,
    authenticator: Authenticator
) {
    val scope = rememberCoroutineScope()
    val favoriteCircles by favorites.circles.collectAsState()
    val favoriteItems by favorites.items.collectAsState()
    val isGroupedByColor by selections.favoritesGroupByColor.collectAsState()
    val displayMode by selections.favoritesDisplayMode.collectAsState()
    val selectedDate by selections.date.collectAsState()
    val authToken by authenticator.token.collectAsState()

    val context = LocalContext.current
    val filters = remember { FavoritesFilters(context) }
    val filteredColors by filters.colors.collectAsState()
    val filteredHalls by filters.halls.collectAsState()
    val mapIDsByBlockID by filters.mapIDsByBlockID.collectAsState()

    var isRefreshing by remember { mutableStateOf(false) }

    LaunchedEffect(favoriteItems, selectedDate) {
        val items = favoriteItems ?: return@LaunchedEffect
        scope.launch(Dispatchers.IO) {
            prepareCircles(items, favorites, filters, selections, database)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        FavoritesToolbar(database = database, filters = filters, selections = selections)

        PullToRefreshBox(
            isRefreshing = isRefreshing,
            onRefresh = {
                val token = authToken
                if (token != null && !isRefreshing) {
                    isRefreshing = true
                    scope.launch {
                        withContext(Dispatchers.IO) {
                            val (items, wcIDMapped) = favoritesAPI.all(token)
                            favorites.setItems(items)
                            favorites.setWcIDMappedItems(wcIDMapped)
                        }
                        isRefreshing = false
                    }
                }
            },
            modifier = Modifier.fillMaxSize()
        ) {
            val circles = favoriteCircles?.let {
                filters.filtered(it, filteredColors, filteredHalls, mapIDsByBlockID)
            }
            if (circles == null) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    if (favoriteItems != null) {
                        CircularProgressIndicator(modifier = Modifier.size(32.dp))
                    } else {
                        Text(
                            text = stringResource(R.string.no_favorites_loaded),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            } else if (circles.values.all { it.isEmpty() }) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = stringResource(R.string.no_favorites_yet),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            } else {
                val isPrivacyMode by selections.isPrivacyMode.collectAsState()
                val showSpaceName by selections.showSpaceName.collectAsState()
                val showDay by selections.showDay.collectAsState()
                val showWebCuts by selections.showWebCuts.collectAsState()
                val gridSize by selections.gridSize.collectAsState()
                val listSize by selections.listSize.collectAsState()

                val onSelect: (ComiketCircle) -> Unit = { circle ->
                    val groupIDs = circles.entries
                        .firstOrNull { entry -> entry.value.any { it.id == circle.id } }
                        ?.value?.map { it.id }
                    unifier.showCircleDetail(circle, groupIDs)
                }

                if (isGroupedByColor && displayMode == CircleDisplayMode.GRID) {
                    ColorGroupedCircleGrid(
                        groups = circles,
                        displayMode = gridSize,
                        database = database,
                        favorites = favorites,
                        showSpaceName = showSpaceName,
                        showDay = showDay,
                        showsOverlayWhenEmpty = false,
                        showUncoloredNotice = true,
                        onSelect = onSelect,
                        isPrivacyMode = isPrivacyMode,
                        showWebCuts = showWebCuts
                    )
                } else if (isGroupedByColor) {
                    ColorGroupedCircleList(
                        groups = circles,
                        displayMode = listSize,
                        database = database,
                        favorites = favorites,
                        showSpaceName = showSpaceName,
                        showDay = showDay,
                        showsOverlayWhenEmpty = false,
                        showUncoloredNotice = true,
                        onSelect = onSelect,
                        isPrivacyMode = isPrivacyMode
                    )
                } else {
                    val flatCircles = circles.values
                        .flatten()
                        .sortedBy { it.id }
                    if (displayMode == CircleDisplayMode.GRID) {
                        CircleGrid(
                            circles = flatCircles,
                            displayMode = gridSize,
                            database = database,
                            favorites = favorites,
                            showSpaceName = showSpaceName,
                            showDay = showDay,
                            showsOverlayWhenEmpty = false,
                            onSelect = onSelect,
                            isPrivacyMode = isPrivacyMode,
                            showWebCuts = showWebCuts
                        )
                    } else {
                        CircleList(
                            circles = flatCircles,
                            displayMode = listSize,
                            database = database,
                            favorites = favorites,
                            showSpaceName = showSpaceName,
                            showDay = showDay,
                            showsOverlayWhenEmpty = false,
                            onSelect = onSelect,
                            isPrivacyMode = isPrivacyMode,
                            showWebCuts = showWebCuts
                        )
                    }
                }
            }
        }
    }
}

private suspend fun prepareCircles(
    favoriteItems: List<com.tsubuzaki.circlesgo.api.catalog.UserFavorites.Response.FavoriteItem>,
    favorites: FavoritesState,
    filters: FavoritesFilters,
    selections: UserSelections,
    database: CatalogDatabase
) {
    val favoriteCircleIdentifiers = FavoritesState.mapped(favoriteItems, database)
    val mapIDsByBlockID = DataFetcher(database.getTextDatabase()).mapIDsByBlockID()
    var hasUncoloredFavorites = false

    val favoriteCircles = mutableMapOf<String, List<ComiketCircle>>()
    val allCircleIDs = mutableListOf<Int>()
    for (colorKey in favoriteCircleIdentifiers.keys.sorted()) {
        val circleIDs = favoriteCircleIdentifiers[colorKey] ?: continue
        var circles = database.circles(circleIDs).sortedBy { it.id }
        val selectedDate = selections.date.value
        if (selectedDate != null) {
            circles = circles.filter { it.day == selectedDate.id }
        }
        if (colorKey == WebCatalogColor.UNCOLORED.value && circles.isNotEmpty()) {
            hasUncoloredFavorites = true
        }
        favoriteCircles[colorKey.toString()] = circles
        allCircleIDs.addAll(circles.map { it.id })
    }
    database.prefetchCircleImages(allCircleIDs)
    filters.setMapIDsByBlockID(mapIDsByBlockID)
    filters.setHasUncoloredFavorites(hasUncoloredFavorites)
    favorites.setCircles(favoriteCircles)
}
