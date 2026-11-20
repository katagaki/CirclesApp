package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Navigator
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import com.tsubuzaki.circlesgo.ui.navi.NaviBuysCarousel
import com.tsubuzaki.circlesgo.ui.navi.NaviUpcomingCircle
import com.tsubuzaki.circlesgo.ui.navi.icon

@Composable
fun UnifiedRouteStepSection(
    navigator: Navigator,
    database: CatalogDatabase,
    favorites: FavoritesState,
    selections: UserSelections,
    unifier: Unifier,
    buysCache: BuysCache,
    eventNumber: Int
) {
    val step = navigator.currentStep ?: return
    val stop = navigator.currentStop ?: return
    val instruction = navigator.currentInstruction ?: return
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .background(MaterialTheme.colorScheme.primary, RoundedCornerShape(14.dp)),
                contentAlignment = Alignment.Center
            ) {
                AnimatedContent(targetState = step.icon, label = "stepIcon") { icon ->
                    Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.onPrimary)
                }
            }
            Box(
                modifier = Modifier.weight(1f).heightIn(min = 48.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                AnimatedContent(targetState = instruction, label = "instruction") { text ->
                    Text(text, style = MaterialTheme.typography.titleMedium)
                }
            }
        }
        if (navigator.skippedSpaces.isNotEmpty()) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Filled.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    stringResource(R.string.route_skipped, navigator.skippedSpaces.joinToString("、")),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        NaviUpcomingCircle(stop, step.isArrival, navigator, database, favorites, selections, unifier)
        Box(modifier = Modifier.fillMaxWidth()) {
            NaviBuysCarousel(stop.circleID, eventNumber, buysCache)
        }
    }
}
