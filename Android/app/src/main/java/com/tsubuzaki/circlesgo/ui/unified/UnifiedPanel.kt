package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.SecondaryTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.data.local.AttachmentsCache
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.CatalogCache
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.UnifiedPath
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.state.VisitsState
import com.tsubuzaki.circlesgo.ui.buys.BuysView
import com.tsubuzaki.circlesgo.ui.catalog.CatalogView
import com.tsubuzaki.circlesgo.ui.circledetail.CircleDetailView
import com.tsubuzaki.circlesgo.ui.favorites.FavoritesView
import com.tsubuzaki.circlesgo.ui.more.EventDataView

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
    authenticator: Authenticator,
    events: Events,
    buysCache: BuysCache,
    visitsState: VisitsState,
    attachmentsCache: AttachmentsCache,
    /** Visible height of the sheet, forwarded to pages that pin content
     *  to their bottom edge. */
    visibleHeight: Dp? = null
) {
    val currentPath by unifier.currentPath.collectAsState()
    val sheetPath by unifier.sheetPath.collectAsState()
    val selectedCircle by unifier.selectedCircle.collectAsState()
    val detailNavigationIDs by unifier.detailNavigationIDs.collectAsState()

    // Favorites only apply to the latest event, so hide the tab when
    // browsing an older Comiket
    val isActiveEventLatest by events.isActiveEventLatestFlow.collectAsState()
    LaunchedEffect(isActiveEventLatest) {
        if (!isActiveEventLatest && currentPath == UnifiedPath.FAVORITES) {
            unifier.setCurrentPath(UnifiedPath.CIRCLES)
        }
    }

    // Check if circle detail is showing (in sheet path stack)
    val isShowingCircleDetail =
        sheetPath.lastOrNull() == UnifiedPath.CIRCLE_DETAIL && selectedCircle != null

    Column(
        modifier = Modifier
            .fillMaxSize()
    ) {
        if (sheetPath.lastOrNull() == UnifiedPath.MORE_DB_ADMIN) {
            // Event data management view (pushed on top)
            EventDataView(
                database = database,
                events = events,
                unifier = unifier
            )
        } else if (isShowingCircleDetail) {
            // Circle detail view (pushed on top)
            CircleDetailView(
                initialCircle = selectedCircle!!,
                database = database,
                favorites = favorites,
                unifier = unifier,
                favoritesAPI = favoritesAPI,
                authenticator = authenticator,
                selections = selections,
                visitsState = visitsState,
                buysCache = buysCache,
                events = events,
                mapper = mapper,
                attachmentsCache = attachmentsCache,
                navigationCircleIDs = detailNavigationIDs,
                visibleHeight = visibleHeight
            )
        } else {
            // Tab row: Circles / Favorites (latest event only) / Buys
            val tabs = if (isActiveEventLatest) {
                listOf(UnifiedPath.CIRCLES, UnifiedPath.FAVORITES, UnifiedPath.BUYS)
            } else {
                listOf(UnifiedPath.CIRCLES, UnifiedPath.BUYS)
            }
            val selectedIndex = tabs.indexOf(currentPath).coerceAtLeast(0)

            SecondaryTabRow(
                selectedTabIndex = selectedIndex,
                containerColor = Color.Transparent
            ) {
                for (tab in tabs) {
                    Tab(
                        selected = currentPath == tab,
                        onClick = { unifier.setCurrentPath(tab) },
                        text = {
                            Text(
                                stringResource(
                                    when (tab) {
                                        UnifiedPath.FAVORITES -> R.string.tab_favorites
                                        UnifiedPath.BUYS -> R.string.tab_buys
                                        else -> R.string.tab_circles
                                    }
                                )
                            )
                        },
                    )
                }
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
                    unifier = unifier,
                    favoritesAPI = favoritesAPI,
                    authenticator = authenticator
                )

                UnifiedPath.BUYS -> BuysView(
                    database = database,
                    buysCache = buysCache,
                    events = events,
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
