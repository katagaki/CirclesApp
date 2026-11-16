package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.VerticalSplit
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Navigator

/**
 * What a long-pressed spot is: where the visitor is standing, or a way that is closed.
 * A tapped closure offers to reopen it instead.
 */
@Composable
fun MapRouteHoldPopover(navigator: Navigator) {
    Column(modifier = Modifier.fillMaxWidth()) {
        if (navigator.pendingPoint != null) {
            Text(
                stringResource(R.string.route_hold_title),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(bottom = 2.dp)
            )
            HoldRow(stringResource(R.string.route_hold_set_origin), Icons.AutoMirrored.Filled.DirectionsWalk) {
                navigator.setOriginAtHold()
            }
            HorizontalDivider(modifier = Modifier.padding(start = 32.dp))
            HoldRow(stringResource(R.string.route_hold_close), Icons.Filled.Block) {
                navigator.closePathAtHold()
            }
            if (navigator.hallBoundaries.isNotEmpty()) {
                HorizontalDivider(modifier = Modifier.padding(start = 32.dp))
                HoldRow(stringResource(R.string.route_hold_close_halls), Icons.Filled.VerticalSplit) {
                    navigator.closeHallsAtHold()
                }
            }
        } else {
            Text(
                stringResource(
                    if (navigator.selectedClosureIsHallBoundary) {
                        R.string.route_closure_halls_title
                    } else {
                        R.string.route_closure_title
                    }
                ),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                stringResource(R.string.route_closure_note),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            HorizontalDivider()
            HoldRow(stringResource(R.string.route_closure_reopen), Icons.AutoMirrored.Filled.Undo) {
                navigator.reopenSelectedClosure()
            }
        }
    }
}

@Composable
private fun HoldRow(title: String, icon: ImageVector, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.width(22.dp))
        Text(title, style = MaterialTheme.typography.bodyLarge)
    }
}
