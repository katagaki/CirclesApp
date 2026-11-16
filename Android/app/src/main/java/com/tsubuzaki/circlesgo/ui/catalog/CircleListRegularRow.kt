package com.tsubuzaki.circlesgo.ui.catalog

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.ui.shared.CircleBlockPill
import com.tsubuzaki.circlesgo.ui.shared.CircleCutImage

@Composable
fun CircleListRegularRow(
    circle: ComiketCircle,
    database: CatalogDatabase,
    favorites: FavoritesState,
    showSpaceName: Boolean,
    showDay: Boolean,
    onClick: () -> Unit,
    isPrivacyMode: Boolean = false,
    showWebCuts: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .width(70.dp)
                .height(100.dp)
        ) {
            CircleCutImage(
                circle = circle,
                database = database,
                favorites = favorites,
                isPrivacyMode = isPrivacyMode,
                showWebCuts = showWebCuts
            )
        }
        Spacer(modifier = Modifier.width(10.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = circle.circleName,
                style = MaterialTheme.typography.bodyLarge
            )
            if (circle.penName.trim().isNotEmpty()) {
                Text(
                    text = circle.penName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            if (showSpaceName || showDay) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (showDay) {
                        CircleBlockPill(text = stringResource(R.string.day_format, circle.day))
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                    if (showSpaceName) {
                        circle.spaceName()?.let { spaceName ->
                            CircleBlockPill(text = spaceName)
                        }
                    }
                }
            }
        }
    }
}
