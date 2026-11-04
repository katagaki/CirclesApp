package com.tsubuzaki.circlesgo.ui.buys

import android.graphics.BitmapFactory
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.data.local.BuysCache

private const val COLUMNS = 3

@Composable
fun <T> BuyItemGrid(
    items: List<T>,
    modifier: Modifier = Modifier,
    tile: @Composable (T) -> Unit
) {
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        items.chunked(COLUMNS).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                row.forEach { Box(modifier = Modifier.weight(1f)) { tile(it) } }
                repeat(COLUMNS - row.size) { Spacer(modifier = Modifier.weight(1f)) }
            }
        }
    }
}

@Composable
fun BuyItemTile(
    name: String,
    cost: Int,
    photo: ByteArray?,
    status: Int,
    onTap: () -> Unit,
    modifier: Modifier = Modifier,
    note: String? = null,
    isHighlighted: Boolean = false,
    onPhotoTap: () -> Unit = onTap,
    accessory: @Composable BoxScope.() -> Unit = {}
) {
    val shape = RoundedCornerShape(10.dp)
    val isCancelled = status == BuysCache.STATUS_CANCELLED
    val isPending = status != BuysCache.STATUS_BOUGHT && !isCancelled
    val dim by animateFloatAsState(if (isPending) 0f else 0.3f, label = "dim")
    val decoration = if (isCancelled) TextDecoration.LineThrough else TextDecoration.None

    Column(modifier = modifier.fillMaxWidth().clickable(onClick = onTap)) {
        Box(modifier = Modifier.fillMaxWidth().aspectRatio(1f)) {
            BuyPhoto(photo, Modifier.fillMaxSize().clickable(onClick = onPhotoTap))
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(shape)
                    .background(Color.Black.copy(alpha = dim))
            )
            if (isHighlighted) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .border(2.dp, MaterialTheme.colorScheme.primary, shape)
                )
            }
            BuyStatusBadge(status, Modifier.align(Alignment.TopStart).padding(6.dp))
            Box(modifier = Modifier.align(Alignment.TopEnd).padding(6.dp)) {
                accessory()
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = name.ifBlank { stringResource(R.string.buys_item_name_placeholder) },
            style = MaterialTheme.typography.bodyMedium,
            textDecoration = decoration,
            color = if (isPending && name.isNotBlank()) {
                MaterialTheme.colorScheme.onSurface
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant
            },
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            text = stringResource(R.string.buys_cost_value, cost),
            style = MaterialTheme.typography.bodySmall,
            fontFamily = FontFamily.Monospace,
            textDecoration = decoration,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        if (note != null) {
            Text(
                text = note,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun BuyStatusBadge(status: Int, modifier: Modifier = Modifier) {
    val fill by animateColorAsState(
        targetValue = when (status) {
            BuysCache.STATUS_BOUGHT -> MaterialTheme.colorScheme.primary
            BuysCache.STATUS_CANCELLED -> MaterialTheme.colorScheme.error
            else -> Color.Black.copy(alpha = 0.25f)
        },
        label = "fill"
    )
    Box(
        modifier = modifier
            .size(24.dp)
            .background(fill, CircleShape)
            .border(1.5.dp, Color.White, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        AnimatedContent(
            targetState = status,
            transitionSpec = {
                (fadeIn() + scaleIn(initialScale = 0.4f))
                    .togetherWith(fadeOut() + scaleOut(targetScale = 0.4f))
            },
            label = "symbol"
        ) { current ->
            val symbol = when (current) {
                BuysCache.STATUS_BOUGHT -> Icons.Filled.Check
                BuysCache.STATUS_CANCELLED -> Icons.Filled.Close
                else -> null
            }
            if (symbol != null) {
                Icon(symbol, null, modifier = Modifier.size(14.dp), tint = Color.White)
            } else {
                Spacer(modifier = Modifier.size(14.dp))
            }
        }
    }
}

@Composable
fun BuyPhoto(data: ByteArray?, modifier: Modifier = Modifier, placeholderDescription: String? = null) {
    val bitmap = remember(data) { data?.let { BitmapFactory.decodeByteArray(it, 0, it.size) } }
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        } else {
            Icon(
                imageVector = Icons.Filled.PhotoCamera,
                contentDescription = placeholderDescription,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
