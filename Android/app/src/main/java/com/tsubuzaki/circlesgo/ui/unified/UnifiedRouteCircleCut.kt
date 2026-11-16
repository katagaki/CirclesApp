package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.ui.shared.CircleCutImage

/** The cut of the circle the route is heading to. Tapping it opens the circle in the panel. */
@Composable
fun UnifiedRouteCircleCut(
    circle: ComiketCircle?,
    database: CatalogDatabase,
    favorites: FavoritesState,
    unifier: Unifier
) {
    val modifier = Modifier.size(width = 56.dp, height = 80.dp)
    if (circle != null) {
        Box(modifier = modifier.clickable { unifier.showCircleDetail(circle) }) {
            CircleCutImage(circle = circle, database = database, favorites = favorites)
        }
    } else {
        Box(modifier = modifier.background(MaterialTheme.colorScheme.surfaceContainerHighest))
    }
}
