package com.tsubuzaki.circlesgo.ui.circledetail

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuyItem
import com.tsubuzaki.circlesgo.ui.buys.BuyItemGrid
import com.tsubuzaki.circlesgo.ui.buys.BuyItemTile
import com.tsubuzaki.circlesgo.ui.shared.LocalSharedBuys
import com.tsubuzaki.circlesgo.ui.sharedbuys.SharedBuyTile

@Composable
fun CircleDetailBuysSection(
    circleID: Int,
    eventNumber: Int,
    buysCache: BuysCache,
    onEdit: () -> Unit,
    modifier: Modifier = Modifier
) {
    val buysVersion by buysCache.version.collectAsState()
    var items by remember { mutableStateOf<List<BuysCache.BuyItem>>(emptyList()) }

    LaunchedEffect(buysVersion, circleID, eventNumber) {
        items = buysCache.entry(circleID, eventNumber)?.items?.sortedBy { it.sortOrder }
            ?: emptyList()
    }

    Column(modifier = modifier) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.buys_section_title),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.weight(1f))
            TextButton(onClick = onEdit) { Text(stringResource(R.string.buys_edit)) }
        }

        val session = LocalSharedBuys.current?.takeIf { it.isActive }
        val sharedItems = session?.items?.filter { it.circleId == circleID }.orEmpty()

        BuyItemGrid<Any>(items + sharedItems) { tile ->
            if (tile is BuysCache.BuyItem) {
                BuyItemTile(
                    name = tile.name,
                    cost = tile.cost,
                    photo = buysCache.image(tile.id).takeIf { buysVersion >= 0 },
                    status = tile.status,
                    onTap = {
                        buysCache.updateItem(
                            circleID,
                            eventNumber,
                            tile.copy(status = BuysCache.nextStatus(tile.status))
                        )
                    }
                )
            } else if (tile is SharedBuyItem && session != null) {
                SharedBuyTile(session, tile)
            }
        }

        if (items.isEmpty() && sharedItems.isEmpty()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onEdit)
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Filled.AddCircle,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = stringResource(R.string.buys_add_item),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}
