package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Navigator

@Composable
fun NaviFavoriteRows(isEnabled: Boolean, onChoose: (Navigator.Mode) -> Unit) {
    NaviModeRow(
        title = stringResource(R.string.route_mode_efficient),
        subtitle = stringResource(R.string.route_mode_efficient_description),
        icon = NaviModeIconKind.AUTOMATIC,
        isEnabled = isEnabled
    ) { onChoose(Navigator.Mode.EFFICIENT) }
    NaviModeRow(
        title = stringResource(R.string.route_mode_prioritized),
        subtitle = stringResource(R.string.route_mode_prioritized_description),
        icon = NaviModeIconKind.COLORS,
        isEnabled = isEnabled
    ) { onChoose(Navigator.Mode.PRIORITIZED) }
}
