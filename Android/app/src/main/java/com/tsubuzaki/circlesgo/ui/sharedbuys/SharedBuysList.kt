package com.tsubuzaki.circlesgo.ui.sharedbuys

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.ShoppingBag
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuyItem
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuyStatus
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession

@Composable
fun SharedBuysList(
    session: SharedBuysSession,
    circlesByID: Map<Int, ComiketCircle>,
    onOpenSession: () -> Unit,
    onStart: () -> Unit
) {
    if (!session.isActive) {
        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
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
                text = stringResource(R.string.buys_shared_not_started),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = stringResource(R.string.buys_shared_explain),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onStart) {
                Text(stringResource(R.string.buys_shared_start))
            }
        }
        return
    }

    val items = session.items
    val circleIDs = items.map { it.circleId }.distinct().sorted()

    LazyColumn(modifier = Modifier.fillMaxSize()) {
        item {
            SharedWithRow(session, onOpenSession)
            if (session.hasUnsentChanges) {
                Text(
                    text = stringResource(R.string.buys_shared_pending),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                )
            }
        }

        if (items.isEmpty()) {
            item {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = stringResource(R.string.buys_shared_no_items),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = stringResource(R.string.buys_shared_no_items_description),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        circleIDs.forEach { circleID ->
            item {
                // The catalog is authoritative and current; the log is what a member
                // without one has. Falling back to it is what keeps a guest's headers
                // readable instead of "Unknown circle 12345".
                val catalog = circlesByID[circleID]
                val relayed = session.circles[circleID]
                val name = catalog?.circleName
                    ?: relayed?.name?.takeIf { it.isNotEmpty() }
                    ?: stringResource(R.string.buys_unknown_circle, circleID)
                val space = catalog?.spaceName() ?: relayed?.space
                Text(
                    text = if (space != null) "$name  $space" else name,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 4.dp)
                )
            }
            items.filter { it.circleId == circleID }.forEach { item ->
                item(key = item.id) {
                    SharedBuyRow(session, item)
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                }
            }
        }

        item {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text(stringResource(R.string.buys_shared_your_share))
                    Spacer(modifier = Modifier.weight(1f))
                    Text("¥${session.yourShare}")
                }
                Spacer(modifier = Modifier.height(6.dp))
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        stringResource(R.string.buys_shared_group_total),
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text("¥${session.groupTotal}", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun SharedWithRow(session: SharedBuysSession, onOpen: () -> Unit) {
    val others = session.members.filterKeys { it != session.actorPid }.values.sorted()
    val title = when (others.size) {
        0 -> stringResource(R.string.buys_shared_only_you)
        1 -> stringResource(R.string.buys_shared_with, others[0])
        2 -> stringResource(R.string.buys_shared_with_two, others[0], others[1])
        else -> stringResource(R.string.buys_shared_with_others, others.size)
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onOpen)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row {
            session.members.values.sorted().forEachIndexed { index, nickname ->
                Box(modifier = Modifier.offset(x = (-8 * index).dp)) {
                    MemberInitial(nickname = nickname)
                }
            }
        }
        Spacer(modifier = Modifier.size(10.dp))
        Text(title, style = MaterialTheme.typography.bodyMedium)
        Spacer(modifier = Modifier.weight(1f))
        Text("›", color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
internal fun SharedBuyRow(session: SharedBuysSession, item: SharedBuyItem) {
    val isMine = item.assignee == session.actorPid
    val toucher = session.members[item.lastTouchedBy]
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                if (isMine) MaterialTheme.colorScheme.primary.copy(alpha = 0.07f) else Color.Transparent
            )
            .clickable { session.cycle(item) }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        when (item.status) {
            SharedBuyStatus.BOUGHT -> Icon(
                Icons.Filled.Check, null, tint = MaterialTheme.colorScheme.primary
            )
            SharedBuyStatus.CANCELLED -> Icon(
                Icons.Filled.Close, null, tint = MaterialTheme.colorScheme.error
            )
            else -> Text("○", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Spacer(modifier = Modifier.size(10.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.name,
                textDecoration = if (item.status == SharedBuyStatus.CANCELLED) {
                    TextDecoration.LineThrough
                } else {
                    TextDecoration.None
                }
            )
            if (item.status != SharedBuyStatus.PENDING &&
                toucher != null &&
                item.lastTouchedBy != session.actorPid
            ) {
                Text(
                    text = stringResource(
                        if (item.status == SharedBuyStatus.BOUGHT) {
                            R.string.buys_shared_bought
                        } else {
                            R.string.buys_shared_cancelled
                        },
                        toucher
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Text("¥${item.cost}", color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(modifier = Modifier.size(10.dp))
        item.assignee?.let { session.members[it] }?.let { MemberInitial(nickname = it, isMine = isMine) }
    }
}
