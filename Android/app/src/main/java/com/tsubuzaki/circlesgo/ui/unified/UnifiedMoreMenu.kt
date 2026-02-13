package com.tsubuzaki.circlesgo.ui.unified

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Unifier

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun UnifiedMoreMenu(
    unifier: Unifier,
    events: com.tsubuzaki.circlesgo.state.Events
) {
    var expanded by remember { mutableStateOf(false) }
    IconButton(
        onClick = { expanded = true },
    ) {
        Icon(
            imageVector = Icons.Default.MoreVert,
            contentDescription = stringResource(R.string.more)
        )
    }
    DropdownMenu(
        expanded = expanded,
        onDismissRequest = { expanded = false }
    ) {
        // Event Picker
        events.eventData?.list?.sortedByDescending { it.number }?.forEach { event ->
            DropdownMenuItem(
                text = { Text(stringResource(R.string.comic_market_format, event.number)) },
                onClick = {
                    expanded = false
                    events.setActiveEvent(event.number)
                },
                leadingIcon = if (event.number == events.activeEventNumber) {
                    {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = "Selected"
                        )
                    }
                } else null
            )
        }
        HorizontalDivider()
        DropdownMenuItem(
            text = { Text(stringResource(R.string.sign_out)) },
            onClick = {
                expanded = false
                unifier.setIsGoingToSignOut(true)
            }
        )
    }
}
