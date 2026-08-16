package com.tsubuzaki.circlesgo.ui.buys

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.ShoppingBag
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
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
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.BuysCache
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.Events
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Purchase planning tab, mirroring the iOS Buys tab: planned items grouped by
 * circle, filtered by the selected day, with a running total and grand total.
 */
@Composable
fun BuysView(
    database: CatalogDatabase,
    buysCache: BuysCache,
    events: Events,
    selections: UserSelections,
    unifier: Unifier
) {
    val buysVersion by buysCache.version.collectAsState()
    val selectedDate by selections.date.collectAsState()
    val eventNumber = events.activeEventNumber

    var entries by remember { mutableStateOf<List<BuysCache.BuyEntry>>(emptyList()) }
    var circlesByID by remember { mutableStateOf<Map<Int, ComiketCircle>>(emptyMap()) }
    var isShowingInfo by remember { mutableStateOf(false) }

    LaunchedEffect(buysVersion, eventNumber) {
        withContext(Dispatchers.IO) {
            val loaded = buysCache.entries(eventNumber)
                .filter { entry -> entry.items.any { it.name.isNotBlank() } }
            val circles = database.circles(loaded.map { it.circleID })
            entries = loaded
            circlesByID = circles.associateBy { it.id }
        }
    }

    val visibleEntries = selectedDate?.let { date ->
        entries.filter { circlesByID[it.circleID]?.day == date.id }
    } ?: entries

    fun cost(of: List<BuysCache.BuyEntry>): Int {
        return of.sumOf { entry ->
            entry.items
                .filter { it.name.isNotBlank() && it.status != BuysCache.STATUS_CANCELLED }
                .sumOf { it.cost }
        }
    }

    val totalCost = cost(visibleEntries)
    val grandTotalCost = cost(entries)

    Column(modifier = Modifier.fillMaxSize()) {
        // Info button row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = { isShowingInfo = true }) {
                Icon(
                    imageVector = Icons.Outlined.Info,
                    contentDescription = stringResource(R.string.buys_info_title),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }

        if (visibleEntries.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Outlined.ShoppingBag,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(
                        if (entries.isEmpty()) R.string.buys_no_buys
                        else R.string.buys_no_buys_on_day
                    ),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = stringResource(
                        if (entries.isEmpty()) R.string.buys_no_buys_description
                        else R.string.buys_no_buys_on_day_description
                    ),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (entries.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(16.dp))
                    TotalRow(
                        label = stringResource(R.string.buys_grand_total),
                        cost = grandTotalCost,
                        emphasized = true
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    horizontal = 16.dp,
                    vertical = 8.dp
                ),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(visibleEntries, key = { it.circleID }) { entry ->
                    val circle = circlesByID[entry.circleID]
                    BuysEntryCard(
                        entry = entry,
                        circle = circle,
                        onItemTapped = { item ->
                            buysCache.updateItem(
                                circleID = entry.circleID,
                                eventNumber = eventNumber,
                                item = item.copy(status = BuysCache.nextStatus(item.status))
                            )
                        },
                        onCircleTapped = {
                            circle?.let { unifier.showCircleDetail(it) }
                        }
                    )
                }
                item {
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    ) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            TotalRow(
                                label = stringResource(R.string.buys_total),
                                cost = totalCost,
                                emphasized = true
                            )
                            if (selectedDate != null) {
                                Spacer(modifier = Modifier.height(4.dp))
                                TotalRow(
                                    label = stringResource(R.string.buys_grand_total),
                                    cost = grandTotalCost,
                                    emphasized = false
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }
        }
    }

    if (isShowingInfo) {
        AlertDialog(
            onDismissRequest = { isShowingInfo = false },
            title = { Text(stringResource(R.string.buys_info_title)) },
            text = { Text(stringResource(R.string.buys_info_description)) },
            confirmButton = {
                TextButton(onClick = { isShowingInfo = false }) {
                    Text(stringResource(R.string.ok))
                }
            }
        )
    }
}

@Composable
private fun TotalRow(label: String, cost: Int, emphasized: Boolean) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (emphasized) FontWeight.Bold else FontWeight.Normal,
            color = if (emphasized) MaterialTheme.colorScheme.onSurface
            else MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.weight(1f))
        Text(
            text = stringResource(R.string.buys_cost_value, cost),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (emphasized) FontWeight.Bold else FontWeight.Normal,
            fontFamily = FontFamily.Monospace,
            color = if (emphasized) MaterialTheme.colorScheme.onSurface
            else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun BuysEntryCard(
    entry: BuysCache.BuyEntry,
    circle: ComiketCircle?,
    onItemTapped: (BuysCache.BuyItem) -> Unit,
    onCircleTapped: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Circle header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(enabled = circle != null) { onCircleTapped() },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = circle?.circleName ?: "#${entry.circleID}",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    circle?.spaceName()?.let { space ->
                        Text(
                            text = stringResource(R.string.day_format, circle.day) + " · " + space,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))
            // Items
            for (item in entry.items.filter { it.name.isNotBlank() }.sortedBy { it.sortOrder }) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onItemTapped(item) }
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
                    Spacer(modifier = Modifier.padding(start = 8.dp))
                    Text(
                        text = item.name,
                        style = MaterialTheme.typography.bodyMedium,
                        textDecoration = if (item.status == BuysCache.STATUS_CANCELLED) {
                            TextDecoration.LineThrough
                        } else {
                            TextDecoration.None
                        },
                        color = if (item.status != BuysCache.STATUS_PENDING) {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        } else {
                            MaterialTheme.colorScheme.onSurface
                        },
                        modifier = Modifier.weight(1f),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
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
        }
    }
}
