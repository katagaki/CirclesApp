package com.tsubuzaki.circlesgo.ui.unified

import androidx.browser.customtabs.CustomTabColorSchemeParams
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowRight
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.core.net.toUri
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Unifier
import com.tsubuzaki.circlesgo.state.UserSelections

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun UnifiedMoreMenu(
    unifier: Unifier,
    events: com.tsubuzaki.circlesgo.state.Events,
    selections: UserSelections
) {
    val context = LocalContext.current
    val primaryColor = MaterialTheme.colorScheme.primary.toArgb()
    var expanded by remember { mutableStateOf(false) }
    var eventSubmenuExpanded by remember { mutableStateOf(false) }
    val showGenreOverlay by selections.showGenreOverlay.collectAsState()

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
        // Event Picker (submenu)
        DropdownMenuItem(
            text = { Text(stringResource(R.string.select_event)) },
            onClick = { eventSubmenuExpanded = true },
            trailingIcon = {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowRight,
                    contentDescription = null
                )
            }
        )

        HorizontalDivider()

        // Genre overlay toggle
        DropdownMenuItem(
            text = { Text(stringResource(R.string.show_genre_overlay)) },
            onClick = { selections.setShowGenreOverlay(!showGenreOverlay) },
            trailingIcon = {
                Switch(
                    checked = showGenreOverlay,
                    onCheckedChange = { selections.setShowGenreOverlay(it) }
                )
            }
        )

        // Darken map in dark mode toggle
        val darkenMapInDarkMode by selections.darkenMapInDarkMode.collectAsState()
        DropdownMenuItem(
            text = { Text(stringResource(R.string.darken_map_in_dark_mode)) },
            onClick = { selections.setDarkenMapInDarkMode(!darkenMapInDarkMode) },
            trailingIcon = {
                Switch(
                    checked = darkenMapInDarkMode,
                    onCheckedChange = { selections.setDarkenMapInDarkMode(it) }
                )
            }
        )

        HorizontalDivider()

        // Show Space Name toggle
        val showSpaceName by selections.showSpaceName.collectAsState()
        DropdownMenuItem(
            text = { Text(stringResource(R.string.show_space_name)) },
            onClick = { selections.setShowSpaceName(!showSpaceName) },
            trailingIcon = {
                Switch(
                    checked = showSpaceName,
                    onCheckedChange = { selections.setShowSpaceName(it) }
                )
            }
        )
        // Show Day toggle
        val showDay by selections.showDay.collectAsState()
        DropdownMenuItem(
            text = { Text(stringResource(R.string.show_day)) },
            onClick = { selections.setShowDay(!showDay) },
            trailingIcon = {
                Switch(
                    checked = showDay,
                    onCheckedChange = { selections.setShowDay(it) }
                )
            }
        )

        HorizontalDivider()

        // Links
        DropdownMenuItem(
            text = { Text(stringResource(R.string.link_web_catalog)) },
            onClick = {
                expanded = false
                val colorSchemeParams = CustomTabColorSchemeParams.Builder()
                    .setToolbarColor(primaryColor)
                    .build()
                val customTabsIntent = CustomTabsIntent.Builder()
                    .setDefaultColorSchemeParams(colorSchemeParams)
                    .build()
                customTabsIntent.launchUrl(context, "https://webcatalog.circle.ms".toUri())
            },
        )
        DropdownMenuItem(
            text = { Text(stringResource(R.string.link_official_site)) },
            onClick = {
                expanded = false
                val colorSchemeParams = CustomTabColorSchemeParams.Builder()
                    .setToolbarColor(primaryColor)
                    .build()
                val customTabsIntent = CustomTabsIntent.Builder()
                    .setDefaultColorSchemeParams(colorSchemeParams)
                    .build()
                customTabsIntent.launchUrl(context, "https://comiket.co.jp".toUri())
            }
        )
        DropdownMenuItem(
            text = { Text(stringResource(R.string.link_floor_map)) },
            onClick = {
                expanded = false
                val colorSchemeParams = CustomTabColorSchemeParams.Builder()
                    .setToolbarColor(primaryColor)
                    .build()
                val customTabsIntent = CustomTabsIntent.Builder()
                    .setDefaultColorSchemeParams(colorSchemeParams)
                    .build()
                customTabsIntent.launchUrl(
                    context,
                    "https://www.bigsight.jp/visitor/floormap/".toUri()
                )
            }
        )

        HorizontalDivider()

        DropdownMenuItem(
            text = { Text(stringResource(R.string.link_source_code)) },
            onClick = {
                expanded = false
                val colorSchemeParams = CustomTabColorSchemeParams.Builder()
                    .setToolbarColor(primaryColor)
                    .build()
                val customTabsIntent = CustomTabsIntent.Builder()
                    .setDefaultColorSchemeParams(colorSchemeParams)
                    .build()
                customTabsIntent.launchUrl(context, "https://github.com/katagaki/CirclesGo".toUri())
            },
        )

        HorizontalDivider()

        // Privacy Mode toggle
        val isPrivacyMode by selections.isPrivacyMode.collectAsState()
        DropdownMenuItem(
            text = { Text(stringResource(R.string.privacy_mode)) },
            onClick = { selections.setIsPrivacyMode(!isPrivacyMode) },
            trailingIcon = {
                Switch(
                    checked = isPrivacyMode,
                    onCheckedChange = { selections.setIsPrivacyMode(it) }
                )
            }
        )

        // Sign out button
        DropdownMenuItem(
            text = { Text(stringResource(R.string.sign_out)) },
            onClick = {
                expanded = false
                unifier.setIsGoingToSignOut(true)
            },
        )
    }

    // Event selection submenu
    DropdownMenu(
        expanded = eventSubmenuExpanded,
        onDismissRequest = { eventSubmenuExpanded = false }
    ) {
        events.eventData?.list?.sortedByDescending { it.number }?.forEach { event ->
            DropdownMenuItem(
                text = { Text(stringResource(R.string.comic_market_format, event.number)) },
                onClick = {
                    eventSubmenuExpanded = false
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
    }
}
