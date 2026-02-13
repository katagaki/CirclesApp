package com.tsubuzaki.circlesgo.ui.map

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp


import com.tsubuzaki.circlesgo.state.PopoverData

@Composable
fun MapLayoutLayer(
    canvasWidth: Dp,
    canvasHeight: Dp,
    popoverData: PopoverData?
) {
    val highlightColor = (if (isSystemInDarkTheme()) Color.White else Color.Black)

    Box(
        modifier = Modifier
            .width(canvasWidth)
            .height(canvasHeight)
    ) {
        // Draw selection highlight
        Canvas(
            modifier = Modifier
                .width(canvasWidth)
                .height(canvasHeight)
        ) {
            popoverData?.let { data ->
                val rect = data.sourceRect
                drawRect(
                    color = highlightColor.copy(alpha = 0.3f),
                    topLeft = Offset(rect.left.dp.toPx(), rect.top.dp.toPx()),
                    size = Size(rect.width().dp.toPx(), rect.height().dp.toPx())
                )
            }
        }

    }
}
