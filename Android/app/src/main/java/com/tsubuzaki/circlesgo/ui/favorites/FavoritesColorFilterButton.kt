package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Palette
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
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
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.state.FavoritesFilters
import com.tsubuzaki.circlesgo.state.UserSelections

@Composable
fun FavoritesColorFilterButton(
    filters: FavoritesFilters,
    selections: UserSelections
) {
    val selectedColors by filters.colors.collectAsState()
    val hasUncoloredFavorites by filters.hasUncoloredFavorites.collectAsState()
    val isGroupedByColor by selections.favoritesGroupByColor.collectAsState()
    var expanded by remember { mutableStateOf(false) }

    val colors = if (hasUncoloredFavorites) {
        listOf(WebCatalogColor.UNCOLORED) + WebCatalogColor.assignable
    } else {
        WebCatalogColor.assignable
    }
    val singleColor = selectedColors.singleOrNull()?.let { value ->
        WebCatalogColor.entries.find { it.value == value }
    }

    Box {
        TextButton(onClick = { expanded = true }) {
            Icon(
                imageVector = Icons.Outlined.Palette,
                contentDescription = null,
                modifier = Modifier
                    .padding(end = 4.dp)
                    .size(18.dp)
            )
            Text(
                text = when {
                    singleColor != null -> stringResource(singleColor.nameRes())
                    selectedColors.size > 1 -> stringResource(R.string.colors_multiple)
                    else -> stringResource(R.string.favorite_color)
                },
                fontSize = 13.sp
            )
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            FavoritesColorFilterPopover(
                colors = colors,
                selectedColors = selectedColors,
                isGroupedByColor = isGroupedByColor,
                onColorToggled = { filters.toggleColor(it.value) },
                onGroupedByColorChanged = { selections.setFavoritesGroupByColor(it) },
                onReset = { filters.setColors(emptySet()) }
            )
        }
    }
}
