package com.tsubuzaki.circlesgo.ui.guest

import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.QrCodeScanner
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.core.net.toUri
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.sharedbuys.SharedBuysSession
import java.util.Locale

@Composable
fun GuestMoreMenu(session: SharedBuysSession, onScan: () -> Unit) {
    val context = LocalContext.current
    val primaryColor = MaterialTheme.colorScheme.primary.toArgb()
    var expanded by remember { mutableStateOf(false) }
    var isConfirmingExit by remember { mutableStateOf(false) }

    fun open(url: String) {
        val colorSchemeParams = CustomTabColorSchemeParams.Builder()
            .setToolbarColor(primaryColor)
            .build()
        CustomTabsIntent.Builder()
            .setDefaultColorSchemeParams(colorSchemeParams)
            .build()
            .launchUrl(context, url.toUri())
    }

    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(
                imageVector = Icons.Default.MoreVert,
                contentDescription = stringResource(R.string.more)
            )
        }
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.guest_scan)) },
                onClick = {
                    expanded = false
                    onScan()
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Outlined.QrCodeScanner,
                        contentDescription = null
                    )
                }
            )

            HorizontalDivider()

            val isJapanese = Locale.getDefault().language == Locale.JAPANESE.language
            DropdownMenuItem(
                text = { Text(stringResource(R.string.link_web_catalog)) },
                onClick = {
                    expanded = false
                    open(
                        if (isJapanese) {
                            "https://webcatalog.circle.ms"
                        } else {
                            "https://int.webcatalog.circle.ms/en/catalog"
                        }
                    )
                }
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.link_official_site)) },
                onClick = {
                    expanded = false
                    open("https://comiket.co.jp")
                }
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.link_floor_map)) },
                onClick = {
                    expanded = false
                    open(
                        if (isJapanese) {
                            "https://www.bigsight.jp/visitor/floormap/"
                        } else {
                            "https://www.bigsight.jp/english/visitor/floormap/"
                        }
                    )
                }
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.link_source_code)) },
                onClick = {
                    expanded = false
                    open("https://github.com/katagaki/CirclesGo")
                }
            )

            HorizontalDivider()

            DropdownMenuItem(
                text = { Text(stringResource(R.string.guest_exit)) },
                onClick = {
                    expanded = false
                    isConfirmingExit = true
                }
            )
        }
    }

    if (isConfirmingExit) {
        AlertDialog(
            onDismissRequest = { isConfirmingExit = false },
            title = { Text(stringResource(R.string.guest_exit_title)) },
            text = { Text(stringResource(R.string.guest_exit_message)) },
            confirmButton = {
                TextButton(onClick = {
                    isConfirmingExit = false
                    session.exitGuestMode()
                }) {
                    Text(stringResource(R.string.guest_exit))
                }
            },
            dismissButton = {
                TextButton(onClick = { isConfirmingExit = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}
