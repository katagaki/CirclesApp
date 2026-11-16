package com.tsubuzaki.circlesgo.wayfinding

/**
 * Erosion and dilation of binary masks with a rectangular structuring element. Kernel
 * sizes are rounded up to odd, and only pixels inside the image are considered, which is
 * how vImage's min and max filters behave on iOS. Each pass keeps a running count over the
 * window, so the cost does not grow with the kernel.
 */
object Morphology {

    fun erode(mask: BooleanArray, width: Int, height: Int, kernelWidth: Int, kernelHeight: Int): BooleanArray =
        filter(mask, width, height, kernelWidth, kernelHeight, usesMinimum = true)

    fun dilate(mask: BooleanArray, width: Int, height: Int, kernelWidth: Int, kernelHeight: Int): BooleanArray =
        filter(mask, width, height, kernelWidth, kernelHeight, usesMinimum = false)

    fun open(mask: BooleanArray, width: Int, height: Int, size: Int): BooleanArray {
        val eroded = erode(mask, width, height, size, size)
        return dilate(eroded, width, height, size, size)
    }

    private fun filter(
        mask: BooleanArray, width: Int, height: Int, kernelWidth: Int, kernelHeight: Int, usesMinimum: Boolean
    ): BooleanArray {
        val horizontal = horizontalPass(mask, width, height, (kernelWidth or 1) / 2, usesMinimum)
        return verticalPass(horizontal, width, height, (kernelHeight or 1) / 2, usesMinimum)
    }

    private fun horizontalPass(
        mask: BooleanArray, width: Int, height: Int, reach: Int, usesMinimum: Boolean
    ): BooleanArray {
        val output = BooleanArray(mask.size)
        for (y in 0 until height) {
            val base = y * width
            var set = 0
            var low = 0
            var high = -1
            for (x in 0 until width) {
                val newHigh = minOf(width - 1, x + reach)
                while (high < newHigh) {
                    high++
                    if (mask[base + high]) set++
                }
                val newLow = maxOf(0, x - reach)
                while (low < newLow) {
                    if (mask[base + low]) set--
                    low++
                }
                val total = high - low + 1
                output[base + x] = if (usesMinimum) set == total else set > 0
            }
        }
        return output
    }

    private fun verticalPass(
        mask: BooleanArray, width: Int, height: Int, reach: Int, usesMinimum: Boolean
    ): BooleanArray {
        val output = BooleanArray(mask.size)
        val counts = IntArray(width)
        var low = 0
        var high = -1
        for (y in 0 until height) {
            val newHigh = minOf(height - 1, y + reach)
            while (high < newHigh) {
                high++
                val base = high * width
                for (x in 0 until width) if (mask[base + x]) counts[x]++
            }
            val newLow = maxOf(0, y - reach)
            while (low < newLow) {
                val base = low * width
                for (x in 0 until width) if (mask[base + x]) counts[x]--
                low++
            }
            val total = high - low + 1
            val base = y * width
            for (x in 0 until width) {
                output[base + x] = if (usesMinimum) counts[x] == total else counts[x] > 0
            }
        }
        return output
    }
}
