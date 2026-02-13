package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.GridDisplayMode
import com.tsubuzaki.circlesgo.ui.shared.CircleCutImage

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ColorGroupedCircleGrid(
    groups: Map<String, List<ComiketCircle>>,
    displayMode: GridDisplayMode,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean = false,
    showDay: Boolean = false,
    showsOverlayWhenEmpty: Boolean = true,
    onSelect: (ComiketCircle) -> Unit
) {
    val minSize = when (displayMode) {
        GridDisplayMode.BIG -> 110.dp
        GridDisplayMode.MEDIUM -> 76.dp
        GridDisplayMode.SMALL -> 48.dp
    }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize),
            modifier = Modifier
                .fillMaxSize(),
            contentPadding = PaddingValues(bottom = FloatingToolbarDefaults.ScreenOffset),
        ) {
            for (color in WebCatalogColor.entries) {
                val circles = groups[color.value.toString()] ?: continue
                // Color section items
                items(
                    items = circles,
                    key = { circle -> circle.id },
                    contentType = { "circle" }
                ) { circle ->
                    Box(
                        modifier = Modifier
                            .padding(0.5.dp)
                            .background(color.backgroundColor().copy(alpha = 0.15f))
                            .clickable { onSelect(circle) }
                    ) {
                        CircleCutImage(
                            circle = circle,
                            database = database,
                            favorites = favorites,
                            displayMode = displayMode,
                            showSpaceName = showSpaceName,
                            showDay = showDay
                        )
                    }
                }
            }
        }

        if (groups.isEmpty() && showsOverlayWhenEmpty) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No circles found.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}
