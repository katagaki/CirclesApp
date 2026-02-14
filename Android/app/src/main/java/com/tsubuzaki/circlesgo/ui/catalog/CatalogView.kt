package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SearchBar
import androidx.compose.material3.SearchBarDefaults
import androidx.compose.material3.Text
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.traversalIndex
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.GridDisplayMode
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CatalogView(
    database: CatalogDatabase,
    selections: UserSelections,
    favorites: FavoritesState,
    mapper: Mapper,
    unifier: Unifier,
    catalogCache: CatalogCache
) {
    val scope = rememberCoroutineScope()
    val isLoading by catalogCache.isLoading.collectAsState()
    val displayedCircles by catalogCache.displayedCircles.collectAsState()
    val searchedCircles by catalogCache.searchedCircles.collectAsState()

    val selectedGenres by selections.genres.collectAsState()
    val selectedBlocks by selections.blocks.collectAsState()
    val selectedMap by selections.map.collectAsState()
    val selectedDate by selections.date.collectAsState()

    // Search state
    var searchTerm by remember { mutableStateOf("") }
    var searchExpanded by remember { mutableStateOf(false) }

    // Notify parent about search active state for bottom sheet expansion
    LaunchedEffect(searchExpanded) {
        unifier.setIsSearchActive(searchExpanded)
    }

    // Reload circles when selection changes
    LaunchedEffect(selectedMap, selectedDate, selectedGenres, selectedBlocks) {
        val catalogSelectionID = selections.catalogSelectionID
        if (catalogCache.invalidationID != catalogSelectionID) {
            reloadDisplayedCircles(catalogCache, selections, database)
        }
    }

    // Search when term changes
    LaunchedEffect(searchTerm) {
        if (searchTerm.isNotEmpty()) {
            scope.launch(Dispatchers.IO) {
                val circleIDs = CatalogCache.searchCircles(searchTerm, database)
                if (circleIDs != null) {
                    val firstPageIDs = circleIDs.take(50)
                    database.prefetchCircleImages(firstPageIDs)
                    val circles = database.circles(firstPageIDs)
                    catalogCache.setSearchedCircles(circles, circleIDs)
                } else {
                    catalogCache.setSearchedCircles(null, null)
                }
            }
        } else {
            catalogCache.setSearchedCircles(null, null)
        }
    }

    var isCurrentlyLoadingMore by remember { mutableStateOf(false) }

    val onLoadMore: () -> Unit = {
        if (!isCurrentlyLoadingMore) {
            isCurrentlyLoadingMore = true
            scope.launch(Dispatchers.IO) {
                try {
                    if (searchedCircles != null) {
                        catalogCache.loadMoreSearchedCircles(database)
                    } else {
                        catalogCache.loadMoreDisplayedCircles(database)
                    }
                } finally {
                    isCurrentlyLoadingMore = false
                }
            }
        }
    }

    // Search bar
    val isPrivacyMode by selections.isPrivacyMode.collectAsState()
    SearchBar(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (!searchExpanded) Modifier.padding(horizontal = 16.dp)
                else Modifier
            )
            .semantics { traversalIndex = -1f },
        inputField = {
            SearchBarDefaults.InputField(
                query = searchTerm,
                onQueryChange = { searchTerm = it },
                onSearch = { searchExpanded = false },
                expanded = searchExpanded,
                onExpandedChange = { searchExpanded = it },
                placeholder = { Text(stringResource(R.string.search_circles_placeholder)) },
                leadingIcon = {
                    if (searchExpanded) {
                        IconButton(onClick = {
                            searchExpanded = false
                            searchTerm = ""
                        }) {
                            Icon(
                                Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = stringResource(R.string.close_search)
                            )
                        }
                    } else {
                        Icon(Icons.Filled.Search, contentDescription = null)
                    }
                },
                trailingIcon = {
                    if (searchTerm.isNotEmpty()) {
                        IconButton(onClick = { searchTerm = "" }) {
                            Icon(
                                Icons.Filled.Close,
                                contentDescription = stringResource(R.string.clear)
                            )
                        }
                    }
                }
            )
        },
        expanded = searchExpanded,
        onExpandedChange = { searchExpanded = it },
        windowInsets = WindowInsets(0, 0, 0, 0),
    ) {
        // Search results view (shown when expanded)
        val currentSearched = searchedCircles
        if (currentSearched != null) {
            CircleGrid(
                circles = currentSearched,
                displayMode = GridDisplayMode.MEDIUM,
                database = database,
                favorites = favorites,
                onSelect = { circle ->
                    searchExpanded = false
                    unifier.showCircleDetail(circle)
                },
                onLoadMore = onLoadMore,
                isLoadingMore = isCurrentlyLoadingMore,
                isPrivacyMode = isPrivacyMode
            )
        } else if (searchTerm.isNotEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = stringResource(R.string.search_min_characters),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }

    // Main content (shown when search is not expanded)
    if (!searchExpanded) {
        CatalogToolbar(
            database = database,
            selections = selections
        )

        Box(modifier = Modifier.fillMaxSize()) {
            if (isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(32.dp))
                }
            } else {
                val hasNoFilter =
                    selectedGenres.isEmpty() && selectedMap == null

                if (hasNoFilter) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = stringResource(R.string.no_filter_selected),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                } else {
                    CircleGrid(
                        circles = displayedCircles,
                        displayMode = GridDisplayMode.MEDIUM,
                        database = database,
                        favorites = favorites,
                        onSelect = { circle ->
                            unifier.showCircleDetail(circle)
                        },
                        onLoadMore = onLoadMore,
                        isLoadingMore = isCurrentlyLoadingMore,
                        isPrivacyMode = isPrivacyMode
                    )
                }
            }
        }
    }
}

private suspend fun reloadDisplayedCircles(
    catalogCache: CatalogCache,
    selections: UserSelections,
    database: CatalogDatabase
) {
    catalogCache.setIsLoading(true)
    catalogCache.invalidationID = selections.catalogSelectionID

    val selectedGenreIDs = selections.genres.value.let { genres ->
        if (genres.isEmpty()) null else genres.map { it.id }
    }
    val selectedMapID = selections.map.value?.id
    val selectedBlockIDs = selections.blocks.value.let { blocks ->
        if (blocks.isEmpty()) null else blocks.map { it.id }
    }
    val selectedDayID = selections.date.value?.id

    val circleIDs = CatalogCache.fetchCircles(
        genreIDs = selectedGenreIDs,
        mapID = selectedMapID,
        blockIDs = selectedBlockIDs,
        dayID = selectedDayID,
        database = database
    )

    val firstPageIDs = circleIDs.take(50)
    database.prefetchCircleImages(firstPageIDs)
    val circles = database.circles(firstPageIDs)
    catalogCache.setDisplayedCircles(circles, circleIDs)
    catalogCache.setIsLoading(false)
}
