package com.tsubuzaki.circlesgo.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialExpressiveTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.expressiveLightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun CirclesGoTheme(content: @Composable () -> Unit) {
    val isDarkTheme = isSystemInDarkTheme()
    val supportsDynamicColor = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

    val colorScheme = when {
        supportsDynamicColor && isDarkTheme -> dynamicDarkColorScheme(LocalContext.current)
        supportsDynamicColor && !isDarkTheme -> dynamicLightColorScheme(LocalContext.current)
        isDarkTheme -> darkColorScheme()
        else -> expressiveLightColorScheme()
    }

    MaterialExpressiveTheme(
        colorScheme = colorScheme,
        shapes = Shapes(largeIncreased = RoundedCornerShape(36.dp)),
        content = content
    )
}