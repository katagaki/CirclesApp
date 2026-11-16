package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.ListDisplayMode

@Composable
fun CircleList(
    circles: List<ComiketCircle>,
    displayMode: ListDisplayMode,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean = false,
    showDay: Boolean = false,
    showsOverlayWhenEmpty: Boolean = true,
    isLoadingMore: Boolean = false,
    onSelect: (ComiketCircle) -> Unit,
    onLoadMore: () -> Unit = {},
    isPrivacyMode: Boolean = false,
    showWebCuts: Boolean = false
) {
    val listState = androidx.compose.foundation.lazy.rememberLazyListState()

    // Trigger onLoadMore when nearing the end, using snapshotFlow to avoid
    // recompositions on every scroll frame
    androidx.compose.runtime.LaunchedEffect(listState, circles.size) {
        androidx.compose.runtime.snapshotFlow {
            listState.layoutInfo.visibleItemsInfo.lastOrNull()?.index
        }.collect { lastIndex ->
            if (lastIndex != null && lastIndex >= circles.size - 10) {
                onLoadMore()
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            state = listState
        ) {
            itemsIndexed(
                items = circles,
                key = { _, circle -> circle.id },
                contentType = { _, _ -> "circle" }
            ) { _, circle ->
                when (displayMode) {
                    ListDisplayMode.REGULAR -> {
                        CircleListRegularRow(
                            circle = circle,
                            database = database,
                            favorites = favorites,
                            showSpaceName = showSpaceName,
                            showDay = showDay,
                            onClick = { onSelect(circle) },
                            isPrivacyMode = isPrivacyMode,
                            showWebCuts = showWebCuts
                        )
                        HorizontalDivider(
                            modifier = Modifier.padding(start = 100.dp)
                        )
                    }

                    ListDisplayMode.COMPACT -> {
                        CircleListCompactRow(
                            circle = circle,
                            database = database,
                            favorites = favorites,
                            showSpaceName = showSpaceName,
                            showDay = showDay,
                            onClick = { onSelect(circle) },
                            isPrivacyMode = isPrivacyMode,
                            showWebCuts = showWebCuts
                        )
                        HorizontalDivider(
                            modifier = Modifier.padding(start = 58.dp)
                        )
                    }
                }
            }

            if (isLoadingMore) {
                item {
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
                    text = stringResource(R.string.no_circles_found_filters),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}
