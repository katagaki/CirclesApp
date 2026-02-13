package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.GridDisplayMode
import com.tsubuzaki.circlesgo.ui.shared.CircleCutImage

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun CircleGrid(
    circles: List<ComiketCircle>,
    displayMode: GridDisplayMode,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean = false,
    showDay: Boolean = false,
    showsOverlayWhenEmpty: Boolean = true,
    isLoadingMore: Boolean = false,
    onSelect: (ComiketCircle) -> Unit,
    onLoadMore: () -> Unit = {}
) {
    val minSize = when (displayMode) {
        GridDisplayMode.BIG -> 110.dp
        GridDisplayMode.MEDIUM -> 76.dp
        GridDisplayMode.SMALL -> 48.dp
    }

    val gridState = androidx.compose.foundation.lazy.grid.rememberLazyGridState()

    // Trigger onLoadMore when nearing the end, using snapshotFlow to avoid
    // recompositions on every scroll frame
    androidx.compose.runtime.LaunchedEffect(gridState, circles.size) {
        androidx.compose.runtime.snapshotFlow {
            gridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index
        }.collect { lastIndex ->
            if (lastIndex != null && lastIndex >= circles.size - 10) {
                onLoadMore()
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize),
            modifier = Modifier
                .fillMaxSize(),
            contentPadding = PaddingValues(bottom = FloatingToolbarDefaults.ScreenOffset),
            state = gridState
        ) {
            itemsIndexed(
                items = circles,
                key = { _, circle -> circle.id },
                contentType = { _, _ -> "circle" }
            ) { _, circle ->
                Box(
                    modifier = Modifier
                        .padding(0.5.dp)
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
            if (isLoadingMore) {
                item(
                    span = {
                        androidx.compose.foundation.lazy.grid.GridItemSpan(maxLineSpan)
                    }
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        androidx.compose.material3.CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            strokeWidth = 2.dp
                        )
                    }
                }
            }
        }

        if (circles.isEmpty() && showsOverlayWhenEmpty) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No circles found.\nTry adjusting filters.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}
