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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.BuysCache

/**
 * Buys editor inside the circle detail view: add items, rename them, set
 * their cost, cycle their status, and delete them.
 */
@Composable
fun CircleDetailBuysSection(
    circleID: Int,
    eventNumber: Int,
    buysCache: BuysCache,
    modifier: Modifier = Modifier
) {
    val buysVersion by buysCache.version.collectAsState()
    var items by remember { mutableStateOf<List<BuysCache.BuyItem>>(emptyList()) }
    var isEditing by remember { mutableStateOf(false) }

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
            if (items.isNotEmpty()) {
                TextButton(onClick = { isEditing = !isEditing }) {
                    Text(
                        stringResource(
                            if (isEditing) R.string.buys_done else R.string.buys_edit
                        )
                    )
                }
            }
        }

        for (item in items) {
            if (isEditing) {
                EditableBuyItemRow(
                    item = item,
                    onUpdate = { updated ->
                        buysCache.updateItem(circleID, eventNumber, updated)
                    },
                    onDelete = {
                        buysCache.deleteItem(circleID, eventNumber, item.id)
                    }
                )
            } else {
                ReadOnlyBuyItemRow(
                    item = item,
                    onTap = {
                        buysCache.updateItem(
                            circleID,
                            eventNumber,
                            item.copy(status = BuysCache.nextStatus(item.status))
                        )
                    }
                )
            }
        }

        // Add item button
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable {
                    buysCache.addItem(circleID, eventNumber)
                    isEditing = true
                }
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

@Composable
private fun ReadOnlyBuyItemRow(
    item: BuysCache.BuyItem,
    onTap: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onTap() }
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        when (item.status) {
            BuysCache.STATUS_BOUGHT -> Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.primary
            )

            BuysCache.STATUS_CANCELLED -> Icon(
                imageVector = Icons.Filled.Close,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )

            else -> Spacer(modifier = Modifier.size(18.dp))
        }
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = item.name.ifBlank { stringResource(R.string.buys_item_name_placeholder) },
            style = MaterialTheme.typography.bodyMedium,
            textDecoration = if (item.status == BuysCache.STATUS_CANCELLED) {
                TextDecoration.LineThrough
            } else {
                TextDecoration.None
            },
            color = if (item.status != BuysCache.STATUS_PENDING || item.name.isBlank()) {
                MaterialTheme.colorScheme.onSurfaceVariant
            } else {
                MaterialTheme.colorScheme.onSurface
            },
            modifier = Modifier.weight(1f)
        )
        Text(
            text = stringResource(R.string.buys_cost_value, item.cost),
            style = MaterialTheme.typography.bodyMedium,
            fontFamily = FontFamily.Monospace,
            textDecoration = if (item.status == BuysCache.STATUS_CANCELLED) {
                TextDecoration.LineThrough
            } else {
                TextDecoration.None
            },
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun EditableBuyItemRow(
    item: BuysCache.BuyItem,
    onUpdate: (BuysCache.BuyItem) -> Unit,
    onDelete: () -> Unit
) {
    var name by remember(item.id) { mutableStateOf(item.name) }
    var costText by remember(item.id) {
        mutableStateOf(if (item.cost == 0 && item.name.isBlank()) "" else item.cost.toString())
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        OutlinedTextField(
            value = name,
            onValueChange = {
                name = it
                onUpdate(item.copy(name = it))
            },
            placeholder = { Text(stringResource(R.string.buys_item_name_placeholder)) },
            modifier = Modifier.weight(1f),
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium
        )
        Spacer(modifier = Modifier.width(8.dp))
        OutlinedTextField(
            value = costText,
            onValueChange = { newValue ->
                costText = newValue
                onUpdate(item.copy(cost = newValue.toIntOrNull() ?: 0))
            },
            placeholder = { Text(stringResource(R.string.buys_item_cost_placeholder)) },
            modifier = Modifier.width(100.dp),
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            textStyle = MaterialTheme.typography.bodyMedium
        )
        IconButton(onClick = onDelete) {
            Icon(
                imageVector = Icons.Outlined.Delete,
                contentDescription = stringResource(R.string.buys_delete),
                tint = MaterialTheme.colorScheme.error
            )
        }
    }
}
