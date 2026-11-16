package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilledTonalIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Navigator

/**
 * End, detour, back and forward keep the same place on every step, so they can be tapped
 * without looking; they only grey out when a step has nothing for them to do.
 */
@Composable
fun NaviStepToolbar(navigator: Navigator) {
    val isOnStep = navigator.currentStep != null && !navigator.isFinished && !navigator.isTrapped
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        NaviEndButton(navigator)
        Spacer(modifier = Modifier.weight(1f))
        OutlinedButton(
            onClick = { navigator.reportBlocked() },
            enabled = isOnStep && navigator.canReportBlocked
        ) {
            Text(stringResource(R.string.route_blocked))
        }
        FilledTonalIconButton(
            onClick = { navigator.previous() },
            enabled = navigator.isFinished || (isOnStep && navigator.stepIndex > 0)
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.route_previous))
        }
        FilledTonalButton(onClick = { navigator.skip() }, enabled = isOnStep) {
            Text(
                stringResource(
                    if (navigator.currentStep?.isArrival == true) R.string.route_skip else R.string.route_next
                )
            )
            Spacer(modifier = Modifier.width(4.dp))
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(18.dp))
        }
    }
}
