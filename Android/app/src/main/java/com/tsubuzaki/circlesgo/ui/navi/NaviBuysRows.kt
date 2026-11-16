package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.tsubuzaki.circlesgo.R

@Composable
fun NaviBuysRows(
    isEnabled: Boolean,
    ownCount: Int,
    sharedCount: Int?,
    onOwn: () -> Unit,
    onShared: () -> Unit
) {
    val resources = LocalContext.current.resources
    fun subtitle(count: Int): String = if (count > 0) {
        resources.getQuantityString(R.plurals.navi_buys_count, count, count)
    } else {
        resources.getString(R.string.navi_buys_none)
    }
    NaviModeRow(
        title = stringResource(R.string.navi_buys_mine),
        subtitle = subtitle(ownCount),
        icon = NaviModeIconKind.OWN_BUYS,
        isEnabled = isEnabled && ownCount > 0,
        onClick = onOwn
    )
    if (sharedCount != null) {
        NaviModeRow(
            title = stringResource(R.string.navi_buys_shared),
            subtitle = subtitle(sharedCount),
            icon = NaviModeIconKind.SHARED_BUYS,
            isEnabled = isEnabled && sharedCount > 0,
            onClick = onShared
        )
    }
}
