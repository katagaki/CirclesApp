package com.tsubuzaki.circlesgo.ui.guest

import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysScanner
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession
import com.tsubuzaki.circlesgo.ui.sharedbuys.SharedBuyRow

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GuestView(session: SharedBuysSession) {
    val context = LocalContext.current
    var isConfirmingLeave by remember { mutableStateOf(false) }

    fun scan() {
        SharedBuysScanner.scan(
            context = context,
            onJoin = { uri ->
                session.adoptIdentity()
                session.join(uri, session.nickname)
            },
            onError = {
                Toast.makeText(
                    context,
                    context.getString(R.string.guest_scan_unavailable),
                    Toast.LENGTH_LONG
                ).show()
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.buys_shared_title)) },
                actions = {
                    GuestMoreMenu(
                        session = session,
                        onScan = { scan() }
                    )
                }
            )
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            if (session.isActive) {
                JoinedList(
                    session = session,
                    onLeave = { isConfirmingLeave = true }
                )
            } else {
                NotJoined(onScan = { scan() })
            }
        }
    }

    if (isConfirmingLeave) {
        AlertDialog(
            onDismissRequest = { isConfirmingLeave = false },
            title = { Text(stringResource(R.string.guest_leave_title)) },
            text = { Text(stringResource(R.string.guest_leave_message)) },
            confirmButton = {
                TextButton(onClick = {
                    isConfirmingLeave = false
                    session.leave()
                }) {
                    Text(stringResource(R.string.guest_leave))
                }
            },
            dismissButton = {
                TextButton(onClick = { isConfirmingLeave = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
private fun NotJoined(onScan: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = stringResource(R.string.guest_not_joined),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.guest_not_joined_description),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(onClick = onScan) {
            Text(stringResource(R.string.guest_scan))
        }
    }
}

@Composable
private fun JoinedList(session: SharedBuysSession, onLeave: () -> Unit) {
    val items = session.items
    val circleIDs = items.map { it.circleId }.distinct().sorted()

    LazyColumn(modifier = Modifier.fillMaxSize()) {
        if (items.isEmpty()) {
            item {
                Text(
                    text = stringResource(R.string.buys_shared_no_items_description),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.fillMaxWidth().padding(24.dp),
                    textAlign = TextAlign.Center
                )
            }
        }
        circleIDs.forEach { circleID ->
            item {
                val relayed = session.circles[circleID]
                val name = relayed?.name?.takeIf { it.isNotEmpty() }
                    ?: stringResource(R.string.buys_unknown_circle, circleID)
                val space = relayed?.space
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
            Row(
                modifier = Modifier.fillMaxWidth().padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = stringResource(R.string.buys_shared_group_total),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = stringResource(R.string.buys_cost_value, session.groupTotal),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
            }
            Text(
                text = stringResource(R.string.guest_read_only),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            Spacer(modifier = Modifier.height(16.dp))
            TextButton(
                onClick = onLeave,
                modifier = Modifier.padding(horizontal = 16.dp)
            ) {
                Text(
                    text = stringResource(R.string.guest_leave),
                    color = MaterialTheme.colorScheme.error
                )
            }
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
