package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Navigator
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.shared.CircleBlockPill
import com.tsubuzaki.circlesgo.ui.unified.UnifiedRouteCircleCut
import com.tsubuzaki.circlesgo.wayfinding.RouteStop
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * The circle the route is heading to, shown on every step so the visitor always knows
 * where the directions lead.
 */
@Composable
fun NaviUpcomingCircle(
    stop: RouteStop,
    isArrival: Boolean,
    navigator: Navigator,
    database: CatalogDatabase,
    favorites: FavoritesState,
    selections: UserSelections,
    unifier: Unifier
) {
    var circle by remember(stop.circleID) { mutableStateOf<ComiketCircle?>(null) }
    LaunchedEffect(stop.circleID) {
        circle = withContext(Dispatchers.IO) { database.circles(listOf(stop.circleID)).firstOrNull() }
    }
    val favoriteItems by favorites.wcIDMappedItems.collectAsState()
    val memo = favoriteItems?.get(stop.id)?.favorite?.memo?.trim().orEmpty()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceContainerHigh, RoundedCornerShape(26.dp))
            .padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        UnifiedRouteCircleCut(circle, database, favorites, selections, unifier)
        Column(
            modifier = Modifier.weight(1f).heightIn(min = 80.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                CircleBlockPill(text = stop.spaceName)
                Text(
                    stop.name,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
            if (memo.isNotEmpty()) {
                Column {
                    Text(
                        stringResource(R.string.navi_favorite_memo),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(memo, style = MaterialTheme.typography.bodyMedium, maxLines = 3, overflow = TextOverflow.Ellipsis)
                }
            }
            if (isArrival) NaviMarkVisitedButton(navigator)
        }
    }
}
