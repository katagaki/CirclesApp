package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp

private val closureRed = Color(0xFFFF3B30)

@Composable
fun MapRouteClosureBadge(size: Dp, isSelected: Boolean, modifier: Modifier = Modifier) {
    Box(modifier = modifier.size(size * 1.8f), contentAlignment = Alignment.Center) {
        if (isSelected) {
            Box(modifier = Modifier.size(size * 1.8f).background(closureRed.copy(alpha = 0.2f), CircleShape))
        }
        Box(
            modifier = Modifier
                .size(size)
                .shadow(size * 0.08f, CircleShape)
                .background(closureRed, CircleShape)
                .border(size * 0.1f, Color.White, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Block, contentDescription = null, tint = Color.White, modifier = Modifier.size(size * 0.55f))
        }
    }
}
