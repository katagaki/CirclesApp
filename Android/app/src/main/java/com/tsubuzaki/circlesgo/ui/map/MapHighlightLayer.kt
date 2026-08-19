package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.tsubuzaki.circlesgo.state.Mapper
import kotlinx.coroutines.delay

/**
 * Blinks a rectangle over the highlighted circle's space ("Show on Map"),
 * mirroring the iOS MapHighlightLayer.
 */
@Composable
fun MapHighlightLayer(
    mapper: Mapper,
    canvasWidth: Dp,
    canvasHeight: Dp
) {
    val highlightData by mapper.highlightData.collectAsState()
    var isVisible by remember { mutableStateOf(true) }

    LaunchedEffect(highlightData) {
        val data = highlightData
        if (data != null && data.shouldBlink) {
            // Blink 7 times at 160 ms
            isVisible = true
            repeat(7) {
                isVisible = !isVisible
                delay(160)
            }
            mapper.setHighlightData(null)
            mapper.setHighlightTarget(null)
        } else {
            isVisible = true
        }
    }

    val data = highlightData
    if (data != null && isVisible) {
        Canvas(
            modifier = Modifier
                .width(canvasWidth)
                .height(canvasHeight)
        ) {
            drawRect(
                color = Color.White,
                topLeft = Offset(
                    data.sourceRect.left.dp.toPx(),
                    data.sourceRect.top.dp.toPx()
                ),
                size = Size(
                    data.sourceRect.width().dp.toPx(),
                    data.sourceRect.height().dp.toPx()
                )
            )
        }
    }
}
