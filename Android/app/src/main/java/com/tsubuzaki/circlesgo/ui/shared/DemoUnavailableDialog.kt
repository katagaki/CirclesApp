package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.tsubuzaki.circlesgo.R

@Composable
fun DemoUnavailableDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.demo_unavailable_title)) },
        text = { Text(stringResource(R.string.demo_unavailable_message)) },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.demo_unavailable_dismiss))
            }
        }
    )
}
