package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Icon
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingToolbarDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
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
    /** Shows the Web Catalog color notice above the uncolored group. */
    showUncoloredNotice: Boolean = false,
    onSelect: (ComiketCircle) -> Unit,
    isPrivacyMode: Boolean = false,
    showWebCuts: Boolean = false
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
                if (showUncoloredNotice && color == WebCatalogColor.UNCOLORED) {
                    item(
                        key = "uncolored_notice",
                        span = { GridItemSpan(maxLineSpan) },
                        contentType = "notice"
                    ) {
                        WebCatalogFavoriteNotice()
                    }
                }
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
                            showDay = showDay,
                            isPrivacyMode = isPrivacyMode,
                            showWebCuts = showWebCuts
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
                    text = stringResource(R.string.no_circles_found),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}

/**
 * Notice shown above uncolored favorites: colors picked from the Web
 * Catalog's own palette are not represented in the app and should be
 * re-selected here.
 */
@Composable
fun WebCatalogFavoriteNotice() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            .padding(horizontal = 20.dp, vertical = 12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Filled.Info,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = stringResource(R.string.favorites_web_catalog_notice_title),
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold
            )
        }
        Text(
            text = stringResource(R.string.favorites_web_catalog_notice_description),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
