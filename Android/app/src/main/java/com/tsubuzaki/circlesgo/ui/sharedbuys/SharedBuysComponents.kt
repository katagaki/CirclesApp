package com.tsubuzaki.circlesgo.ui.sharedbuys

import android.graphics.Bitmap
import android.graphics.Color
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.Color as ComposeColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter

private val palette = listOf(
    ComposeColor(0xFFFF832B), ComposeColor(0xFF009D9A), ComposeColor(0xFF8A3FFC),
    ComposeColor(0xFFD02670), ComposeColor(0xFF4589FF), ComposeColor(0xFF198038)
)

@Composable
fun MemberInitial(nickname: String, size: Int = 26, isMine: Boolean = false) {
    // Widened before taking the magnitude: abs(Int.MIN_VALUE) is still negative, which
    // would index the palette out of bounds. iOS mirrors this hash so the same member
    // draws the same colour on both platforms.
    val color = palette[((nickname.hashCode().toLong().let { if (it < 0) -it else it }) % palette.size).toInt()]
    Box(
        modifier = Modifier
            .size(size.dp)
            .background(color, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = nickname.take(1),
            color = ComposeColor.White,
            fontSize = (size * 0.45).sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun JoinCodeImage(contents: String, size: Int = 200) {
    val bitmap = remember(contents) { qrBitmap(contents, 600) }
    if (bitmap != null) {
        Image(
            bitmap = bitmap.asImageBitmap(),
            contentDescription = null,
            modifier = Modifier.size(size.dp)
        )
    }
}

private fun qrBitmap(contents: String, pixels: Int): Bitmap? = runCatching {
    val matrix = QRCodeWriter().encode(contents, BarcodeFormat.QR_CODE, pixels, pixels)
    val bitmap = Bitmap.createBitmap(pixels, pixels, Bitmap.Config.ARGB_8888)
    for (x in 0 until pixels) {
        for (y in 0 until pixels) {
            bitmap.setPixel(x, y, if (matrix[x, y]) Color.BLACK else Color.WHITE)
        }
    }
    bitmap
}.getOrNull()
