package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Navigator

@Composable
fun NaviModesSection(
    isEnabled: Boolean,
    ownBuysCount: Int,
    sharedBuysCount: Int?,
    onChoose: (Navigator.Mode) -> Unit,
    onOwnBuys: () -> Unit,
    onSharedBuys: () -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            stringResource(R.string.navi_modes),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.surfaceContainerHigh
        ) {
            Column(modifier = Modifier.padding(vertical = 4.dp)) {
                NaviFavoriteRows(isEnabled = isEnabled, onChoose = onChoose)
                NaviBuysRows(
                    isEnabled = isEnabled,
                    ownCount = ownBuysCount,
                    sharedCount = sharedBuysCount,
                    onOwn = onOwnBuys,
                    onShared = onSharedBuys
                )
            }
        }
        if (sharedBuysCount != null) {
            Text(
                stringResource(R.string.navi_buys_shared_footer),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
        }
    }
}
