package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.SecondaryTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.UnifiedPath
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.catalog.CatalogView
import com.tsubuzaki.circlesgo.ui.circledetail.CircleDetailView
import com.tsubuzaki.circlesgo.ui.favorites.FavoritesView

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun UnifiedPanel(
    unifier: Unifier,
    database: CatalogDatabase,
    favorites: FavoritesState,
    selections: UserSelections,
    mapper: Mapper,
    catalogCache: CatalogCache,
    favoritesAPI: FavoritesAPI,
    authenticator: Authenticator
) {
    val currentPath by unifier.currentPath.collectAsState()
    val sheetPath by unifier.sheetPath.collectAsState()
    val selectedCircle by unifier.selectedCircle.collectAsState()

    // Check if circle detail is showing (in sheet path stack)
    val isShowingCircleDetail =
        sheetPath.lastOrNull() == UnifiedPath.CIRCLE_DETAIL && selectedCircle != null

    Column(
        modifier = Modifier
            .fillMaxSize()
    ) {
        if (isShowingCircleDetail) {
            // Circle detail view (pushed on top)
            CircleDetailView(
                circle = selectedCircle!!,
                database = database,
                favorites = favorites,
                unifier = unifier,
                favoritesAPI = favoritesAPI,
                authenticator = authenticator
            )
        } else {
            // Tab row: Circles / Favorites
            val tabs = listOf(UnifiedPath.CIRCLES, UnifiedPath.FAVORITES)
            val selectedIndex = tabs.indexOf(currentPath).coerceAtLeast(0)

            SecondaryTabRow(
                selectedTabIndex = selectedIndex,
                containerColor = Color.Transparent
            ) {
                Tab(
                    selected = currentPath == UnifiedPath.CIRCLES,
                    onClick = { unifier.setCurrentPath(UnifiedPath.CIRCLES) },
                    text = { Text(stringResource(R.string.tab_circles)) },
                )
                Tab(
                    selected = currentPath == UnifiedPath.FAVORITES,
                    onClick = { unifier.setCurrentPath(UnifiedPath.FAVORITES) },
                    text = { Text(stringResource(R.string.tab_favorites)) },
                )
            }

            // Content based on current path
            when (currentPath) {
                UnifiedPath.CIRCLES -> CatalogView(
                    database = database,
                    selections = selections,
                    favorites = favorites,
                    mapper = mapper,
                    unifier = unifier,
                    catalogCache = catalogCache
                )

                UnifiedPath.FAVORITES -> FavoritesView(
                    database = database,
                    favorites = favorites,
                    selections = selections,
                    unifier = unifier
                )

                else -> CatalogView(
                    database = database,
                    selections = selections,
                    favorites = favorites,
                    mapper = mapper,
                    unifier = unifier,
                    catalogCache = catalogCache
                )
            }
        }
    }
}
