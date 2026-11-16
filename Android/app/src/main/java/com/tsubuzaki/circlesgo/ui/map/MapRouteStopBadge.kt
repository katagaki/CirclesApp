package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp

enum class MapRouteStopPhase { DONE, CURRENT, UPCOMING }

@Composable
fun MapRouteStopBadge(number: Int, phase: MapRouteStopPhase, size: Dp, modifier: Modifier = Modifier) {
    val accent = MaterialTheme.colorScheme.primary
    val fill = when (phase) {
        MapRouteStopPhase.DONE -> MaterialTheme.colorScheme.outline
        MapRouteStopPhase.CURRENT -> accent
        MapRouteStopPhase.UPCOMING -> MaterialTheme.colorScheme.surface
    }
    val content = if (phase == MapRouteStopPhase.UPCOMING) accent else Color.White
    val ring = if (phase == MapRouteStopPhase.UPCOMING) accent else Color.White
    val ringWidth = size * if (phase == MapRouteStopPhase.UPCOMING) 0.12f else 0.1f
    val fontSize = with(LocalDensity.current) { (size * 0.5f).toSp() }
    Box(
        modifier = modifier
            .size(size)
            .shadow(size * 0.08f, CircleShape)
            .background(fill, CircleShape)
            .border(ringWidth, ring, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        if (phase == MapRouteStopPhase.DONE) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = content, modifier = Modifier.size(size * 0.55f))
        } else {
            Text("$number", color = content, fontSize = fontSize, fontWeight = FontWeight.Bold)
        }
    }
}
