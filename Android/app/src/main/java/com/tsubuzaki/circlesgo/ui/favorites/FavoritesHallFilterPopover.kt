package com.tsubuzaki.circlesgo.ui.favorites

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.tables.ComiketMap

@Composable
fun FavoritesHallFilterPopover(
    maps: List<ComiketMap>,
    selectedHalls: Set<Int>,
    onHallToggled: (ComiketMap) -> Unit,
    onReset: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(240.dp)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            maps.chunked(2).forEach { rowMaps ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    rowMaps.forEach { map ->
                        FavoritesHallFilterOption(
                            name = map.name,
                            isSelected = map.id in selectedHalls,
                            onClick = { onHallToggled(map) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    if (rowMaps.size < 2) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }
        }
        Button(
            onClick = onReset,
            enabled = selectedHalls.isNotEmpty(),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(text = stringResource(R.string.all_filter), fontWeight = FontWeight.Bold)
        }
    }
}
