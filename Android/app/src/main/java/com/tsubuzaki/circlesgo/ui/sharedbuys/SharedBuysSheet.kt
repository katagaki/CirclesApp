package com.tsubuzaki.circlesgo.ui.sharedbuys

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SharedBuysSheet(session: SharedBuysSession, onDismiss: () -> Unit) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = stringResource(R.string.buys_shared_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            session.joinUrl?.let { JoinCodeImage(contents = it) }
            Text(
                text = stringResource(R.string.buys_shared_scan_to_join),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Text(
                text = stringResource(R.string.buys_shared_members),
                style = MaterialTheme.typography.labelLarge,
                modifier = Modifier.fillMaxWidth()
            )
            session.members.entries.sortedBy { it.value }.forEach { member ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    MemberInitial(
                        nickname = member.value,
                        size = 30,
                        isMine = member.key == session.actorPid
                    )
                    Modifier.size(10.dp)
                    Text(
                        text = "  ${member.value}",
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f)
                    )
                    if (session.isOwner && member.key != session.actorPid) {
                        TextButton(
                            onClick = { session.rotateKey(removing = member.key) },
                            enabled = session.canRotateKey
                        ) {
                            Text(
                                text = stringResource(R.string.buys_shared_remove),
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
            if (session.isOwner) {
                TextButton(onClick = { session.rotateKey() }, enabled = session.canRotateKey) {
                    Text(text = stringResource(R.string.buys_shared_rotate_key))
                }
                Text(
                    text = stringResource(R.string.buys_shared_rotate_key_explain),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
            TextButton(onClick = {
                session.leave()
                onDismiss()
            }) {
                Text(
                    text = stringResource(R.string.buys_shared_end),
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}
