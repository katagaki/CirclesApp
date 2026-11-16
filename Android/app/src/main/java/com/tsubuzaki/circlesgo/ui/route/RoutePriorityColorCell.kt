package com.tsubuzaki.circlesgo.ui.route

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor

@Composable
fun RoutePriorityColorCell(color: WebCatalogColor, rank: Int?, count: Int, modifier: Modifier = Modifier) {
    val description = LocalContext.current.resources.getQuantityString(R.plurals.route_priority_count, count, count)
    Box(
        modifier = modifier
            .size(56.dp)
            .shadow(if (rank == null) 0.dp else 3.dp, CircleShape)
            .background(color.backgroundColor().copy(alpha = if (rank == null) 0.3f else 1f), CircleShape)
            .semantics {
                contentDescription = description
                selected = rank != null
            },
        contentAlignment = Alignment.Center
    ) {
        if (rank == null) {
            Icon(
                Icons.Filled.Close,
                contentDescription = null,
                tint = color.backgroundColor(),
                modifier = Modifier.size(24.dp)
            )
        } else {
            Text(
                "$rank",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = color.foregroundColor()
            )
        }
    }
}
