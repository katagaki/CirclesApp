package com.tsubuzaki.circlesgo.ui.map

import android.graphics.Bitmap
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize

private val invertColorMatrix = ColorMatrix(
    floatArrayOf(
        -1f, 0f, 0f, 0f, 255f,
        0f, -1f, 0f, 0f, 255f,
        0f, 0f, -1f, 0f, 255f,
        0f, 0f, 0f, 1f, 0f
    )
)

@Composable
fun MapImageLayer(
    bitmap: Bitmap,
    canvasWidth: Dp,
    canvasHeight: Dp
) {
    val isDarkTheme = isSystemInDarkTheme()
    val imageBitmap = bitmap.asImageBitmap()

    val colorFilter = if (isDarkTheme) ColorFilter.colorMatrix(invertColorMatrix) else null

    Canvas(
        modifier = Modifier
            .size(canvasWidth, canvasHeight)
    ) {
        val scaledWidth = imageBitmap.width * density
        val scaledHeight = imageBitmap.height * density

        drawImage(
            image = imageBitmap,
            dstSize = IntSize(scaledWidth.toInt(), scaledHeight.toInt()),
            colorFilter = colorFilter
        )
    }
}
