package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Navigator

@Composable
fun NaviEndButton(navigator: Navigator) {
    var isConfirmingEnd by remember { mutableStateOf(false) }
    Button(
        onClick = { isConfirmingEnd = true },
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.error,
            contentColor = MaterialTheme.colorScheme.onError
        )
    ) {
        Text(stringResource(R.string.route_end_short), fontWeight = FontWeight.SemiBold)
    }
    if (isConfirmingEnd) {
        AlertDialog(
            onDismissRequest = { isConfirmingEnd = false },
            title = { Text(stringResource(R.string.route_end_confirm)) },
            confirmButton = {
                TextButton(onClick = {
                    isConfirmingEnd = false
                    navigator.end()
                }) {
                    Text(stringResource(R.string.route_end), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { isConfirmingEnd = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}
