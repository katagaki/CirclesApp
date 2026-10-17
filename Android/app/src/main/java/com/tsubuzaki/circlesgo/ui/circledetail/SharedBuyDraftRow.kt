package com.tsubuzaki.circlesgo.ui.circledetail

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.ui.shared.LocalSharedBuys
import kotlinx.coroutines.delay
import java.util.UUID

private const val SYNC_DEBOUNCE_MILLIS = 1000L

class SharedBuyDraft {
    val id: String = UUID.randomUUID().toString()
    var itemId: String? by mutableStateOf(null)
}

@Composable
fun SharedBuyDraftRow(
    circleID: Int,
    draft: SharedBuyDraft,
    onDelete: () -> Unit,
    /**
     * The circle's name and space, relayed into the log alongside the first item from
     * this circle so a guest -- who has no catalog database -- can still read the header.
     */
    circleName: String? = null,
    circleSpace: String? = null
) {
    val session = LocalSharedBuys.current
    var name by remember { mutableStateOf("") }
    var costText by remember { mutableStateOf("") }
    var syncedName by remember { mutableStateOf("") }
    var syncedCost by remember { mutableStateOf(0) }

    LaunchedEffect(name, costText) {
        val trimmed = name.trim()
        if (session == null || trimmed.isEmpty()) return@LaunchedEffect
        delay(SYNC_DEBOUNCE_MILLIS)
        val cost = costText.toIntOrNull() ?: 0
        val itemId = draft.itemId
        if (itemId == null) {
            draft.itemId = session.addItem(trimmed, cost, circleID, circleName, circleSpace)
            syncedName = trimmed
            syncedCost = cost
        } else {
            if (trimmed != syncedName) {
                session.rename(itemId, circleID, trimmed)
                syncedName = trimmed
            }
            if (cost != syncedCost) {
                session.setCost(itemId, circleID, cost)
                syncedCost = cost
            }
        }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Filled.PersonAdd,
            contentDescription = null,
            modifier = Modifier.size(18.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.width(8.dp))
        OutlinedTextField(
            value = name,
            onValueChange = { name = it },
            placeholder = { Text(stringResource(R.string.buys_item_name_placeholder)) },
            modifier = Modifier.weight(1f),
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium
        )
        Spacer(modifier = Modifier.width(8.dp))
        OutlinedTextField(
            value = costText,
            onValueChange = { newValue -> costText = newValue.filter { it.isDigit() } },
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
