package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
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
import com.tsubuzaki.circlesgo.state.ListDisplayMode

@Composable
fun ColorGroupedCircleList(
    groups: Map<String, List<ComiketCircle>>,
    displayMode: ListDisplayMode,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean = false,
    showDay: Boolean = false,
    showsOverlayWhenEmpty: Boolean = true,
    onSelect: (ComiketCircle) -> Unit,
    isPrivacyMode: Boolean = false
) {
    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            for (color in WebCatalogColor.entries) {
                val circles = groups[color.value.toString()] ?: continue
                items(
                    items = circles,
                    key = { circle -> circle.id },
                    contentType = { "circle" }
                ) { circle ->
                    val bgColor = color.backgroundColor().copy(alpha = 0.15f)
                    when (displayMode) {
                        ListDisplayMode.REGULAR -> {
                            Box(modifier = Modifier.background(bgColor)) {
                                CircleListRegularRow(
                                    circle = circle,
                                    database = database,
                                    favorites = favorites,
                                    showSpaceName = showSpaceName,
                                    showDay = showDay,
                                    onClick = { onSelect(circle) },
                                    isPrivacyMode = isPrivacyMode
                                )
                            }
                            HorizontalDivider(
                                modifier = Modifier
                                    .padding(start = 100.dp)
                                    .background(bgColor)
                            )
                        }

                        ListDisplayMode.COMPACT -> {
                            Box(modifier = Modifier.background(bgColor)) {
                                CircleListCompactRow(
                                    circle = circle,
                                    database = database,
                                    favorites = favorites,
                                    showSpaceName = showSpaceName,
                                    showDay = showDay,
                                    onClick = { onSelect(circle) },
                                    isPrivacyMode = isPrivacyMode
                                )
                            }
                            HorizontalDivider(
                                modifier = Modifier
                                    .padding(start = 58.dp)
                                    .background(bgColor)
                            )
                        }
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
