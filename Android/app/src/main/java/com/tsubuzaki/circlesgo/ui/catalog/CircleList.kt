package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.ListDisplayMode
import com.tsubuzaki.circlesgo.ui.shared.CircleBlockPill
import com.tsubuzaki.circlesgo.ui.shared.CircleBlockPillSize
import com.tsubuzaki.circlesgo.ui.shared.CircleCutImage

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
    onLoadMore: () -> Unit = {}
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
                            onClick = { onSelect(circle) }
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
                            onClick = { onSelect(circle) }
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
                    text = "No circles found.\nTry adjusting filters.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}

@Composable
fun CircleListRegularRow(
    circle: ComiketCircle,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean,
    showDay: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(70.dp)
                .height(100.dp)
        ) {
            CircleCutImage(
                circle = circle,
                database = database,
                favorites = favorites
            )
        }
        Spacer(modifier = Modifier.width(10.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = circle.circleName,
                style = MaterialTheme.typography.bodyLarge
            )
            if (circle.penName.trim().isNotEmpty()) {
                Text(
                    text = circle.penName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (showSpaceName || showDay) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (showDay) {
                        CircleBlockPill(text = "Day ${circle.day}")
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    if (showSpaceName) {
                        circle.spaceName()?.let { spaceName ->
                            CircleBlockPill(text = spaceName)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun CircleListCompactRow(
    circle: ComiketCircle,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean,
    showDay: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(28.dp)
                .height(40.dp)
        ) {
            CircleCutImage(
                circle = circle,
                database = database,
                favorites = favorites
            )
        }
        Spacer(modifier = Modifier.width(10.dp))
        Text(
            text = circle.circleName,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f)
        )
        if (showSpaceName || showDay) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (showDay) {
                    CircleBlockPill(
                        text = "Day ${circle.day}",
                        size = CircleBlockPillSize.SMALL
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                }
                if (showSpaceName) {
                    circle.spaceName()?.let { spaceName ->
                        CircleBlockPill(
                            text = spaceName,
                            size = CircleBlockPillSize.SMALL
                        )
                    }
                }
            }
        }
    }
}
