package com.tsubuzaki.circlesgo.wayfinding

import android.graphics.Bitmap
import kotlin.math.max
import kotlin.math.min

/**
 * The map image split into the ink classes the wayfinder cares about. Block letters are
 * green and float over the aisles, so they are painted out before edges are looked for.
 * Gray levels are stored as unsigned bytes.
 */
class MapRaster private constructor(
    val dark: BooleanArray,
    val fillOrDark: BooleanArray,
    val neutralGray: ByteArray,
    val gray: ByteArray
) {

    fun grayAt(index: Int): Int = gray[index].toInt() and 0xFF

    companion object {
        fun from(bitmap: Bitmap): MapRaster {
            val width = bitmap.width
            val height = bitmap.height
            val count = width * height
            val dark = BooleanArray(count)
            val fillOrDark = BooleanArray(count)
            val neutralGray = ByteArray(count)
            val plainGray = ByteArray(count)
            val row = IntArray(width)
            for (y in 0 until height) {
                bitmap.getPixels(row, 0, width, 0, y, width, 1)
                for (x in 0 until width) {
                    val pixel = row[x]
                    val alpha = (pixel ushr 24) and 0xFF
                    val red = over((pixel shr 16) and 0xFF, alpha)
                    val green = over((pixel shr 8) and 0xFF, alpha)
                    val blue = over(pixel and 0xFF, alpha)
                    val grayValue = (299 * red + 587 * green + 114 * blue) / 1000
                    val saturation = max(red, max(green, blue)) - min(red, min(green, blue))
                    val isLabel = saturation > 60 && green > red && green > blue
                    val isDark = grayValue < 140 && saturation < 40
                    val isFill = grayValue in 140 until 245 && saturation < 25
                    val index = y * width + x
                    dark[index] = isDark
                    fillOrDark[index] = isDark || isFill
                    neutralGray[index] = (if (isLabel) 255 else grayValue).toByte()
                    plainGray[index] = grayValue.toByte()
                }
            }
            return MapRaster(dark, fillOrDark, neutralGray, plainGray)
        }

        /** The image is drawn over white, so transparent pixels read as paper. */
        private fun over(channel: Int, alpha: Int): Int =
            (channel * alpha + 255 * (255 - alpha)) / 255
    }
}
