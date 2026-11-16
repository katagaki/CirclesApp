package com.tsubuzaki.circlesgo.ui.route

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.tsubuzaki.circlesgo.R

/** Shown each time a route starts, until the visitor asks not to see it again. */
@Composable
fun RouteSafetyAlert(onGotIt: () -> Unit, onDontShowAgain: () -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        text = { Text(stringResource(R.string.route_safety_alert_title)) },
        confirmButton = {
            TextButton(onClick = onGotIt) { Text(stringResource(R.string.route_safety_alert_got_it)) }
        },
        dismissButton = {
            TextButton(onClick = onDontShowAgain) {
                Text(stringResource(R.string.route_safety_alert_dont_show_again))
            }
        }
    )
}
