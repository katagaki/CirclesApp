package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.GridDisplayMode
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.catalog.CircleGrid
import com.tsubuzaki.circlesgo.ui.catalog.ColorGroupedCircleGrid
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Composable
fun FavoritesView(
    database: CatalogDatabase,
    favorites: FavoritesState,
    selections: UserSelections,
    unifier: Unifier
) {
    val scope = rememberCoroutineScope()
    val favoriteCircles by favorites.circles.collectAsState()
    val favoriteItems by favorites.items.collectAsState()
    val isGroupedByColor by favorites.isGroupedByColor.collectAsState()
    val selectedDate by selections.date.collectAsState()

    // Prepare circles when favorite items or selected date changes
    LaunchedEffect(favoriteItems, selectedDate) {
        val items = favoriteItems ?: return@LaunchedEffect
        scope.launch(Dispatchers.IO) {
            prepareCircles(items, favorites, selections, database)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Toolbar row: group by color toggle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Spacer(modifier = Modifier.weight(1f))
            TextButton(onClick = { favorites.toggleGroupByColor() }) {
                Icon(
                    imageVector = Icons.Filled.Palette,
                    contentDescription = null,
                    modifier = Modifier
                        .padding(end = 4.dp)
                        .size(18.dp)
                )
                Text(
                    text = stringResource(R.string.group_by_color),
                    fontSize = 13.sp
                )
            }
        }

        // Content area
        Box(modifier = Modifier.fillMaxSize()) {
            val circles = favoriteCircles
            if (circles == null) {
                // Loading or no favorites loaded yet
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
            } else if (circles.isEmpty()) {
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
                if (isGroupedByColor) {
                    ColorGroupedCircleGrid(
                        groups = circles,
                        displayMode = GridDisplayMode.MEDIUM,
                        database = database,
                        favorites = favorites,
                        showSpaceName = showSpaceName,
                        showDay = showDay,
                        showsOverlayWhenEmpty = false,
                        onSelect = { circle ->
                            unifier.showCircleDetail(circle)
                        },
                        isPrivacyMode = isPrivacyMode
                    )
                } else {
                    val flatCircles = circles.values
                        .flatten()
                        .sortedBy { it.id }
                    CircleGrid(
                        circles = flatCircles,
                        displayMode = GridDisplayMode.MEDIUM,
                        database = database,
                        favorites = favorites,
                        showSpaceName = showSpaceName,
                        showDay = showDay,
                        showsOverlayWhenEmpty = false,
                        onSelect = { circle ->
                            unifier.showCircleDetail(circle)
                        },
                        isPrivacyMode = isPrivacyMode
                    )
                }
            }
        }
    }
}

private suspend fun prepareCircles(
    favoriteItems: List<com.tsubuzaki.circlesgo.api.catalog.UserFavorites.Response.FavoriteItem>,
    favorites: FavoritesState,
    selections: UserSelections,
    database: CatalogDatabase
) {
    val favoriteCircleIdentifiers = FavoritesState.mapped(favoriteItems, database)

    val favoriteCircles = mutableMapOf<String, List<ComiketCircle>>()
    val allCircleIDs = mutableListOf<Int>()
    for (colorKey in favoriteCircleIdentifiers.keys.sorted()) {
        val circleIDs = favoriteCircleIdentifiers[colorKey] ?: continue
        var circles = database.circles(circleIDs).sortedBy { it.id }
        val selectedDate = selections.date.value
        if (selectedDate != null) {
            circles = circles.filter { it.day == selectedDate.id }
        }
        favoriteCircles[colorKey.toString()] = circles
        allCircleIDs.addAll(circles.map { it.id })
    }
    database.prefetchCircleImages(allCircleIDs)
    favorites.setCircles(favoriteCircles)
}
