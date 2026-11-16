package com.tsubuzaki.circlesgo.ui.route

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.state.Navigator

/** What Guide does, shown before the first route and from the Navi tab's help button. */
@Composable
fun RouteOnboardingView(navigator: Navigator, onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = navigator.hasSeenOnboarding,
            dismissOnClickOutside = false,
            decorFitsSystemWindows = false
        )
    ) {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.surface) {
            Column(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .padding(bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(28.dp)
                ) {
                    RouteOnboardingHero(
                        modifier = Modifier
                            .background(MaterialTheme.colorScheme.surfaceContainer)
                            .statusBarsPadding()
                            .padding(start = 24.dp, end = 24.dp, top = 16.dp, bottom = 28.dp)
                    )
                    Column(
                        modifier = Modifier.padding(horizontal = 24.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            stringResource(R.string.route_onboarding_title),
                            style = MaterialTheme.typography.headlineLarge,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            stringResource(R.string.route_onboarding_subtitle),
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Column(
                        modifier = Modifier.padding(horizontal = 24.dp),
                        verticalArrangement = Arrangement.spacedBy(22.dp)
                    ) {
                        RouteOnboardingRow(
                            stringResource(R.string.route_onboarding_modes_title),
                            stringResource(R.string.route_onboarding_modes_message),
                            RouteOnboardingIconKind.MODES
                        )
                        RouteOnboardingRow(
                            stringResource(R.string.route_onboarding_origin_title),
                            stringResource(R.string.route_onboarding_origin_message),
                            RouteOnboardingIconKind.ORIGIN
                        )
                        RouteOnboardingRow(
                            stringResource(R.string.route_onboarding_steps_title),
                            stringResource(R.string.route_onboarding_steps_message),
                            RouteOnboardingIconKind.STEPS
                        )
                        RouteOnboardingRow(
                            stringResource(R.string.route_onboarding_detour_title),
                            stringResource(R.string.route_onboarding_detour_message),
                            RouteOnboardingIconKind.DETOUR
                        )
                    }
                }
                Button(
                    onClick = {
                        navigator.setHasSeenOnboarding()
                        onDismiss()
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .navigationBarsPadding()
                        .padding(horizontal = 24.dp, vertical = 12.dp)
                ) {
                    Text(
                        stringResource(R.string.route_onboarding_start),
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(vertical = 6.dp)
                    )
                }
            }
        }
    }
}
