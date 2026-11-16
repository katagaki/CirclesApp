package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.TableRows
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.state.CircleDisplayMode
import com.tsubuzaki.circlesgo.state.FavoritesFilters
import com.tsubuzaki.circlesgo.state.UserSelections

@Composable
fun FavoritesToolbar(
    database: CatalogDatabase,
    filters: FavoritesFilters,
    selections: UserSelections
) {
    val displayMode by selections.favoritesDisplayMode.collectAsState()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        FavoritesColorFilterButton(filters = filters, selections = selections)
        FavoritesHallFilterButton(database = database, filters = filters)
        Spacer(modifier = Modifier.weight(1f))
        IconButton(onClick = {
            selections.setFavoritesDisplayMode(
                if (displayMode == CircleDisplayMode.GRID) CircleDisplayMode.LIST
                else CircleDisplayMode.GRID
            )
        }) {
            Icon(
                imageVector = if (displayMode == CircleDisplayMode.GRID) {
                    Icons.Outlined.TableRows
                } else {
                    Icons.Outlined.GridView
                },
                contentDescription = stringResource(
                    if (displayMode == CircleDisplayMode.GRID) R.string.switch_to_list
                    else R.string.switch_to_grid
                )
            )
        }
    }
}
