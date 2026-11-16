package com.tsubuzaki.circlesgo.wayfinding

import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * Canny edge detection: Gaussian smoothing, Sobel gradients, non-maximum suppression along
 * the gradient direction, then hysteresis so weak edges survive only when they touch a
 * strong one.
 */
object EdgeDetector {

    private val neighbours = arrayOf(intArrayOf(0, 1), intArrayOf(1, 1), intArrayOf(1, 0), intArrayOf(1, -1))

    fun edges(gray: ByteArray, width: Int, height: Int, low: Float = 0.08f, high: Float = 0.2f): BooleanArray {
        val count = width * height
        if (width < 3 || height < 3) return BooleanArray(count)
        val smooth = blur(gray, width, height)
        val magnitude = FloatArray(count)
        val sector = ByteArray(count)
        var peak = 0f

        for (row in 1 until height - 1) {
            val above = (row - 1) * width
            val here = row * width
            val below = (row + 1) * width
            for (column in 1 until width - 1) {
                val topLeft = (smooth[above + column - 1].toInt() and 0xFF).toFloat()
                val top = (smooth[above + column].toInt() and 0xFF).toFloat()
                val topRight = (smooth[above + column + 1].toInt() and 0xFF).toFloat()
                val left = (smooth[here + column - 1].toInt() and 0xFF).toFloat()
                val right = (smooth[here + column + 1].toInt() and 0xFF).toFloat()
                val bottomLeft = (smooth[below + column - 1].toInt() and 0xFF).toFloat()
                val bottom = (smooth[below + column].toInt() and 0xFF).toFloat()
                val bottomRight = (smooth[below + column + 1].toInt() and 0xFF).toFloat()
                val gx = (topRight + 2 * right + bottomRight) - (topLeft + 2 * left + bottomLeft)
                val gy = (bottomLeft + 2 * bottom + bottomRight) - (topLeft + 2 * top + topRight)
                val value = sqrt(gx * gx + gy * gy)
                magnitude[here + column] = value
                if (value > peak) peak = value
                var angle = (atan2(gy, gx) * 180.0f / Math.PI.toFloat())
                if (angle < 0) angle += 180.0f
                sector[here + column] = (((angle + 22.5f) / 45.0f).toInt() % 4).toByte()
            }
        }
        if (peak <= 0f) return BooleanArray(count)

        val lowThreshold = low * peak
        val highThreshold = high * peak
        val state = ByteArray(count)
        val stack = IntStack()
        for (row in 1 until height - 1) {
            for (column in 1 until width - 1) {
                val index = row * width + column
                val value = magnitude[index]
                if (value < lowThreshold) continue
                val direction = neighbours[sector[index].toInt()]
                val dy = direction[0]
                val dx = direction[1]
                val ahead = magnitude[(row + dy) * width + column + dx]
                val behind = magnitude[(row - dy) * width + column - dx]
                if (value < ahead || value < behind) continue
                if (value >= highThreshold) {
                    state[index] = 2
                    stack.push(index)
                } else {
                    state[index] = 1
                }
            }
        }

        val result = BooleanArray(count)
        while (!stack.isEmpty()) {
            val index = stack.pop()
            if (result[index]) continue
            result[index] = true
            val row = index / width
            val column = index % width
            for (dy in -1..1) {
                for (dx in -1..1) {
                    val nextRow = row + dy
                    val nextColumn = column + dx
                    if (nextRow < 0 || nextRow >= height || nextColumn < 0 || nextColumn >= width) continue
                    val next = nextRow * width + nextColumn
                    if (state[next] > 0 && !result[next]) stack.push(next)
                }
            }
        }
        return result
    }

    /** A 5×5 binomial blur, with the image's edge pixels extended past its border. */
    private fun blur(gray: ByteArray, width: Int, height: Int): ByteArray {
        val taps = intArrayOf(1, 4, 6, 4, 1)
        val horizontal = ShortArray(gray.size)
        for (y in 0 until height) {
            val base = y * width
            for (x in 0 until width) {
                var sum = 0
                for (tap in -2..2) {
                    val sampleX = (x + tap).coerceIn(0, width - 1)
                    sum += taps[tap + 2] * (gray[base + sampleX].toInt() and 0xFF)
                }
                horizontal[base + x] = sum.toShort()
            }
        }
        val output = ByteArray(gray.size)
        for (y in 0 until height) {
            for (x in 0 until width) {
                var sum = 0
                for (tap in -2..2) {
                    val sampleY = (y + tap).coerceIn(0, height - 1)
                    sum += taps[tap + 2] * horizontal[sampleY * width + x]
                }
                output[y * width + x] = ((sum + 128) / 256).coerceAtMost(255).toByte()
            }
        }
        return output
    }
}
