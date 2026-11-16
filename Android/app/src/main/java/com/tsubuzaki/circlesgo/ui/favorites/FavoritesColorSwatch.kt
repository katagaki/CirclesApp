package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor

@Composable
fun FavoritesColorSwatch(
    color: WebCatalogColor,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val name = stringResource(color.nameRes())
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(CircleShape)
            .background(color.backgroundColor())
            .border(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f), CircleShape)
            .clickable(onClick = onClick)
            .semantics {
                contentDescription = name
                selected = isSelected
            },
        contentAlignment = Alignment.Center
    ) {
        if (isSelected) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = color.foregroundColor(),
                modifier = Modifier.size(24.dp)
            )
        }
    }
}
