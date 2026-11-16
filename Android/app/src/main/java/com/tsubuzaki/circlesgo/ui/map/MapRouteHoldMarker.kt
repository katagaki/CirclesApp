package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.QuestionMark
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.Dp

@Composable
fun MapRouteHoldMarker(size: Dp, modifier: Modifier = Modifier) {
    val ink = MaterialTheme.colorScheme.onSurface
    Box(modifier = modifier.size(size * 1.8f), contentAlignment = Alignment.Center) {
        Box(modifier = Modifier.size(size * 1.8f).background(ink.copy(alpha = 0.15f), CircleShape))
        Box(
            modifier = Modifier
                .size(size)
                .shadow(size * 0.08f, CircleShape)
                .background(MaterialTheme.colorScheme.surface, CircleShape)
                .border(size * 0.12f, ink, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.QuestionMark, contentDescription = null, tint = ink, modifier = Modifier.size(size * 0.5f))
        }
    }
}
