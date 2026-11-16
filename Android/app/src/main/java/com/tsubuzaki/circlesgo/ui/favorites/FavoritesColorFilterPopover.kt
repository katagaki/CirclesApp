package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor

@Composable
fun FavoritesColorFilterPopover(
    colors: List<WebCatalogColor>,
    selectedColors: Set<Int>,
    isGroupedByColor: Boolean,
    onColorToggled: (WebCatalogColor) -> Unit,
    onGroupedByColorChanged: (Boolean) -> Unit,
    onReset: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(248.dp)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = stringResource(R.string.select_color),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
            colors.chunked(4).forEach { rowColors ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    rowColors.forEach { color ->
                        FavoritesColorSwatch(
                            color = color,
                            isSelected = color.value in selectedColors,
                            onClick = { onColorToggled(color) }
                        )
                    }
                }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(R.string.group_by_color),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(modifier = Modifier.weight(1f))
            Switch(checked = isGroupedByColor, onCheckedChange = onGroupedByColorChanged)
        }
        Button(
            onClick = onReset,
            enabled = selectedColors.isNotEmpty(),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(text = stringResource(R.string.all_filter), fontWeight = FontWeight.Bold)
        }
    }
}
