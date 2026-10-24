package com.tsubuzaki.circlesgo.ui.shared

import androidx.compose.foundation.border
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

enum class CircleBlockPillSize {
    LARGE,
    SMALL,
    TINY
}

@Composable
fun CircleBlockPill(
    text: String,
    size: CircleBlockPillSize = CircleBlockPillSize.SMALL
) {
    Surface(
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.8f),
        modifier = Modifier.border(
            width = (1f / 3f).dp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
            shape = CircleShape
        )
    ) {
        when (size) {
            CircleBlockPillSize.LARGE -> {
                Text(
                    text = text,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(vertical = 2.dp, horizontal = 10.dp)
                )
            }

            CircleBlockPillSize.SMALL -> {
                Text(
                    text = text,
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(vertical = 2.dp, horizontal = 6.dp)
                )
            }

            CircleBlockPillSize.TINY -> {
                Text(
                    text = text,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(vertical = 1.dp, horizontal = 3.dp)
                )
            }
        }
    }
}
