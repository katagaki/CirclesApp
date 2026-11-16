package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R

/**
 * Every way to the remaining favourites is closed. There is nothing to do but wait, so
 * this says so plainly instead of offering choices.
 */
@Composable
fun UnifiedRouteTrappedSection() {
    Column(modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(stringResource(R.string.route_trapped_title), style = MaterialTheme.typography.titleMedium)
        Text(
            stringResource(R.string.route_trapped_message),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
