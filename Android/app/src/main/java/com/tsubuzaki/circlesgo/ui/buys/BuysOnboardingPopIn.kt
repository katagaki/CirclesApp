package com.tsubuzaki.circlesgo.ui.buys

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale

@Composable
fun BuysOnboardingPopIn(isShown: Boolean, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val progress by animateFloatAsState(
        targetValue = if (isShown) 1f else 0f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMediumLow),
        label = "pop"
    )
    Box(
        modifier = modifier
            .scale(0.2f + 0.8f * progress)
            .alpha(progress.coerceIn(0f, 1f))
    ) {
        content()
    }
}
