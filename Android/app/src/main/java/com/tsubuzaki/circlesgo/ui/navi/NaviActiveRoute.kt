package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Navigator
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.ui.unified.UnifiedRouteStepSection
import com.tsubuzaki.circlesgo.ui.unified.UnifiedRouteTrappedSection

@Composable
fun NaviActiveRoute(
    navigator: Navigator,
    database: CatalogDatabase,
    favorites: FavoritesState,
    unifier: Unifier,
    buysCache: BuysCache,
    eventNumber: Int,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 12.dp)
    ) {
        when {
            navigator.isFinished -> NaviFinishedCard(navigator.route?.stops?.size ?: 0)
            navigator.isTrapped -> UnifiedRouteTrappedSection()
            navigator.currentStep == null -> NaviPlanningCard()
            else -> UnifiedRouteStepSection(navigator, database, favorites, unifier, buysCache, eventNumber)
        }
    }
}
