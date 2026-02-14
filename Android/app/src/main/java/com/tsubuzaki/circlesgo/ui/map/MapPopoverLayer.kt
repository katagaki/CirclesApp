package com.tsubuzaki.circlesgo.ui.map

import android.graphics.PointF
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import com.tsubuzaki.circlesgo.state.FavoritesState
import com.tsubuzaki.circlesgo.state.Mapper
import com.tsubuzaki.circlesgo.state.PopoverData
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun MapPopoverLayer(
    popoverData: PopoverData,
    zoomScale: Float,
    canvasWidth: Dp,
    canvasHeight: Dp,
    mapper: Mapper,
    database: CatalogDatabase,
    favorites: FavoritesState,
    onCircleTapped: (ComiketCircle) -> Unit
) {
    var circles by remember { mutableStateOf<List<ComiketCircle>?>(null) }

    LaunchedEffect(popoverData.id) {
        circles = null
        withContext(Dispatchers.IO) {
            val fetcher = DataFetcher(database.getTextDatabase())
            val circleIDs = fetcher.circlesWithWebCatalogIDs(popoverData.ids)
            circles = database.circles(circleIDs, reversed = popoverData.reversed)
        }
        // Set popover position for auto-scroll
        mapper.setPopoverPosition(
            PointF(popoverData.sourceRect.centerX(), popoverData.sourceRect.centerY())
        )
    }

    val position = calculatePopoverPosition(
        sourceRect = popoverData.sourceRect,
        canvasWidth = canvasWidth,
        canvasHeight = canvasHeight,
        popoverWidth = mapper.popoverWidth,
        popoverHeight = mapper.popoverHeight,
        popoverDistance = mapper.popoverDistance,
        popoverEdgePadding = mapper.popoverEdgePadding,
        zoomScale = zoomScale
    )

    var visible by remember(popoverData.id) { mutableStateOf(false) }
    LaunchedEffect(popoverData.id) {
        visible = true
    }

    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(animationSpec = tween(200)) + scaleIn(
            initialScale = 0.8f,
            animationSpec = tween(250)
        ),
        exit = fadeOut(animationSpec = tween(150)) + scaleOut(
            targetScale = 0.8f,
            animationSpec = tween(150)
        )
    ) {
        Box(
            modifier = Modifier
                .offset {
                    IntOffset(
                        (position.x - mapper.popoverWidth / 2).dp.roundToPx(),
                        (position.y - mapper.popoverHeight / 2).dp.roundToPx()
                    )
                }
                .width(mapper.popoverWidth.dp)
                .height(IntrinsicSize.Min)
                .shadow(8.dp, RoundedCornerShape(12.dp))
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surface)
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
            ) {
                val currentCircles = circles
                if (currentCircles != null) {
                    for (circle in currentCircles) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onCircleTapped(circle) }
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .width(40.dp)
                                    .height(57.dp)
                            ) {
                                com.tsubuzaki.circlesgo.ui.shared.CircleCutImage(
                                    circle = circle,
                                    database = database,
                                    favorites = favorites,
                                    displayMode = com.tsubuzaki.circlesgo.state.GridDisplayMode.SMALL
                                )
                            }
                            Spacer(modifier = Modifier.width(8.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = circle.circleName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    maxLines = 2
                                )
                                circle.spaceName()?.let { space ->
                                    Text(
                                        text = space,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                    }
                } else {
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(stringResource(R.string.loading))
                    }
                }
            }
        }
    }
}

private fun calculatePopoverPosition(
    sourceRect: android.graphics.RectF,
    canvasWidth: Dp,
    canvasHeight: Dp,
    popoverWidth: Float,
    popoverHeight: Float,
    popoverDistance: Float,
    popoverEdgePadding: Float,
    zoomScale: Float
): PointF {
    val cw = canvasWidth.value
    val ch = canvasHeight.value

    val pw = popoverWidth / zoomScale
    val ph = popoverHeight / zoomScale
    val dist = popoverDistance / zoomScale
    val pad = popoverEdgePadding / zoomScale

    val effectiveHeight = maxOf(ph, 150f)
    val cx = sourceRect.centerX()
    val cy = sourceRect.centerY()
    val halfW = sourceRect.width() / 2
    val halfH = sourceRect.height() / 2
    val minOffX = halfW + dist + (pw / 2)
    val minOffY = halfH + dist + (effectiveHeight / 2)

    val canFitRight = cw - pad - (cx + minOffX + pw / 2) >= 0
    val canFitLeft = (cx - minOffX - pw / 2) - pad >= 0
    val canFitBelow = ch - pad - (cy + minOffY + effectiveHeight / 2) >= 0
    val canFitAbove = (cy - minOffY - effectiveHeight / 2) - pad >= 0

    val nearTop = cy < ch * 0.3f
    val nearBottom = cy > ch * 0.7f

    var posX: Float
    var posY: Float

    when {
        nearTop && canFitBelow -> {
            posX = cx; posY = cy + minOffY
        }

        nearBottom && canFitAbove -> {
            posX = cx; posY = cy - minOffY
        }

        canFitRight -> {
            posX = cx + minOffX; posY = cy
            if (posY + effectiveHeight / 2 > ch - pad)
                posY = ch - pad - effectiveHeight / 2
            if (posY - effectiveHeight / 2 < pad)
                posY = pad + effectiveHeight / 2
        }

        canFitLeft -> {
            posX = cx - minOffX; posY = cy
            if (posY + effectiveHeight / 2 > ch - pad)
                posY = ch - pad - effectiveHeight / 2
            if (posY - effectiveHeight / 2 < pad)
                posY = pad + effectiveHeight / 2
        }

        canFitBelow -> {
            posX = cx; posY = cy + minOffY
        }

        canFitAbove -> {
            posX = cx; posY = cy - minOffY
        }

        else -> {
            posX = cx + minOffX; posY = cy
        }
    }

    posX = posX.coerceIn(pad + pw / 2, cw - pad - pw / 2)
    posY = posY.coerceIn(pad + effectiveHeight / 2, ch - pad - effectiveHeight / 2)

    return PointF(posX, posY)
}
