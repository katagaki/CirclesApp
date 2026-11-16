package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Apartment
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketMap
import com.tsubuzaki.circlesgo.state.FavoritesFilters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun FavoritesHallFilterButton(
    database: CatalogDatabase,
    filters: FavoritesFilters
) {
    val selectedHalls by filters.halls.collectAsState()
    val commonImagesLoadCount by database.commonImagesLoadCount.collectAsState()
    var maps by remember { mutableStateOf(emptyList<ComiketMap>()) }
    var expanded by remember { mutableStateOf(false) }

    LaunchedEffect(commonImagesLoadCount) {
        val loadedMaps = withContext(Dispatchers.IO) { database.maps() }
        if (loadedMaps.isNotEmpty()) {
            maps = loadedMaps
        }
    }

    val singleHall = selectedHalls.singleOrNull()?.let { id -> maps.find { it.id == id } }

    Box {
        TextButton(onClick = { expanded = true }) {
            Icon(
                imageVector = Icons.Outlined.Apartment,
                contentDescription = null,
                modifier = Modifier
                    .padding(end = 4.dp)
                    .size(18.dp)
            )
            Text(
                text = when {
                    singleHall != null -> singleHall.name
                    selectedHalls.size > 1 -> stringResource(R.string.halls_multiple)
                    else -> stringResource(R.string.hall_filter)
                },
                fontSize = 13.sp
            )
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            FavoritesHallFilterPopover(
                maps = maps,
                selectedHalls = selectedHalls,
                onHallToggled = { filters.toggleHall(it.id) },
                onReset = { filters.setHalls(emptySet()) }
            )
        }
    }
}
