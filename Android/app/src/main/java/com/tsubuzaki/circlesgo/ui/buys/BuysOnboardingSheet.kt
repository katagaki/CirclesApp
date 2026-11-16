package com.tsubuzaki.circlesgo.ui.buys

import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ModalBottomSheetProperties
import androidx.compose.material3.SheetValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.ui.shared.OnboardingRow
import kotlinx.coroutines.launch

/**
 * Introduces Buys the first time the tab opens, and again from its help button.
 *
 * Until it has been seen once it can only be left through Get Started.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BuysOnboardingSheet(hasSeenOnboarding: Boolean, onStart: () -> Unit, onDismiss: () -> Unit) {
    val hasSeen by rememberUpdatedState(hasSeenOnboarding)
    var isStarting by remember { mutableStateOf(false) }
    val canDismiss = hasSeen || isStarting
    val sheetState = rememberModalBottomSheetState(
        skipPartiallyExpanded = true,
        confirmValueChange = { it != SheetValue.Hidden || hasSeen || isStarting }
    )
    val coroutineScope = rememberCoroutineScope()
    val isDark = isSystemInDarkTheme()
    val sheetColor = if (isDark) MaterialTheme.colorScheme.surfaceContainerLow else MaterialTheme.colorScheme.surface
    val heroBandColor = if (isDark) Color.Black else MaterialTheme.colorScheme.surfaceContainerHigh
    val heroCardColor = if (isDark) MaterialTheme.colorScheme.surfaceContainerHighest else MaterialTheme.colorScheme.surface

    ModalBottomSheet(
        onDismissRequest = { if (canDismiss) onDismiss() },
        sheetState = sheetState,
        containerColor = sheetColor,
        dragHandle = null,
        properties = ModalBottomSheetProperties(shouldDismissOnBackPress = hasSeenOnboarding)
    ) {
        Column {
            Column(
                modifier = Modifier
                    .weight(1f, fill = false)
                    .verticalScroll(rememberScrollState())
                    .padding(bottom = 16.dp),
                verticalArrangement = Arrangement.spacedBy(28.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(heroBandColor)
                        .padding(horizontal = 24.dp)
                        .padding(bottom = 28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    BottomSheetDefaults.DragHandle()
                    BuysOnboardingHero(cardColor = heroCardColor)
                }
                Column(
                    modifier = Modifier.padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = stringResource(R.string.buys_onboarding_title),
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = stringResource(R.string.buys_onboarding_subtitle),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Column(
                    modifier = Modifier.padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(22.dp)
                ) {
                    OnboardingRow(
                        title = stringResource(R.string.buys_onboarding_add_title),
                        message = stringResource(R.string.buys_onboarding_add_message)
                    ) { BuysOnboardingIcon(BuysOnboardingIconKind.ADD) }
                    OnboardingRow(
                        title = stringResource(R.string.buys_onboarding_track_title),
                        message = stringResource(R.string.buys_onboarding_track_message)
                    ) { BuysOnboardingIcon(BuysOnboardingIconKind.TRACK) }
                    OnboardingRow(
                        title = stringResource(R.string.buys_onboarding_share_title),
                        message = stringResource(R.string.buys_onboarding_share_message)
                    ) { BuysOnboardingIcon(BuysOnboardingIconKind.SHARE) }
                    OnboardingRow(
                        title = stringResource(R.string.buys_onboarding_split_title),
                        message = stringResource(R.string.buys_onboarding_split_message)
                    ) { BuysOnboardingIcon(BuysOnboardingIconKind.SPLIT) }
                }
            }
            Button(
                onClick = {
                    isStarting = true
                    onStart()
                    coroutineScope.launch { sheetState.hide() }.invokeOnCompletion { onDismiss() }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp)
                    .padding(top = 4.dp, bottom = 12.dp)
            ) {
                Text(
                    text = stringResource(R.string.buys_onboarding_start),
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(vertical = 6.dp)
                )
            }
        }
    }
}
