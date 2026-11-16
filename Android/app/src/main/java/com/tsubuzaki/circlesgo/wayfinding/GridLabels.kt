package com.tsubuzaki.circlesgo.wayfinding

class GridLabels(val values: IntArray, val count: Int) {

    companion object {

        /** Four-connected component labelling; labels start at 1 and 0 marks cells left out. */
        fun label(mask: BooleanArray, rows: Int, columns: Int): GridLabels {
            val values = IntArray(mask.size)
            var next = 0
            val stack = IntStack()
            for (start in mask.indices) {
                if (!mask[start] || values[start] != 0) continue
                next += 1
                values[start] = next
                stack.push(start)
                while (!stack.isEmpty()) {
                    val index = stack.pop()
                    val row = index / columns
                    val column = index % columns
                    if (column > 0 && mask[index - 1] && values[index - 1] == 0) {
                        values[index - 1] = next
                        stack.push(index - 1)
                    }
                    if (column < columns - 1 && mask[index + 1] && values[index + 1] == 0) {
                        values[index + 1] = next
                        stack.push(index + 1)
                    }
                    if (row > 0 && mask[index - columns] && values[index - columns] == 0) {
                        values[index - columns] = next
                        stack.push(index - columns)
                    }
                    if (row < rows - 1 && mask[index + columns] && values[index + columns] == 0) {
                        values[index + columns] = next
                        stack.push(index + columns)
                    }
                }
            }
            return GridLabels(values, next)
        }

        fun largestComponent(mask: BooleanArray, rows: Int, columns: Int): BooleanArray {
            val labels = label(mask, rows, columns)
            if (labels.count <= 0) return mask
            val area = IntArray(labels.count + 1)
            for (value in labels.values) if (value > 0) area[value] += 1
            var largest = 1
            for (label in 2..labels.count) if (area[label] > area[largest]) largest = label
            return BooleanArray(mask.size) { labels.values[it] == largest }
        }

        fun reachableFromBorder(mask: BooleanArray, rows: Int, columns: Int): BooleanArray {
            val reached = BooleanArray(mask.size)
            val stack = IntStack()
            for (row in 0 until rows) {
                for (column in 0 until columns) {
                    val isBorder = row == 0 || column == 0 || row == rows - 1 || column == columns - 1
                    if (isBorder && mask[row * columns + column]) {
                        reached[row * columns + column] = true
                        stack.push(row * columns + column)
                    }
                }
            }
            while (!stack.isEmpty()) {
                val index = stack.pop()
                val row = index / columns
                val column = index % columns
                for ((dy, dx) in FOUR_WAYS) {
                    val nextRow = row + dy
                    val nextColumn = column + dx
                    if (nextRow < 0 || nextRow >= rows || nextColumn < 0 || nextColumn >= columns) continue
                    val next = nextRow * columns + nextColumn
                    if (mask[next] && !reached[next]) {
                        reached[next] = true
                        stack.push(next)
                    }
                }
            }
            return reached
        }

        /**
         * Morphological closing with a straight line, which bridges gaps up to `length` cells
         * along that direction and nowhere else.
         */
        fun closeAlongLine(
            mask: BooleanArray, rows: Int, columns: Int, direction: Pair<Int, Int>, length: Int
        ): BooleanArray {
            val reach = length / 2
            fun sweep(input: BooleanArray, keepsWhenAny: Boolean): BooleanArray {
                val output = BooleanArray(input.size)
                for (row in 0 until rows) {
                    for (column in 0 until columns) {
                        var any = false
                        var all = true
                        for (step in -reach..reach) {
                            val sampleRow = row + step * direction.first
                            val sampleColumn = column + step * direction.second
                            val value = if (sampleRow in 0 until rows && sampleColumn in 0 until columns) {
                                input[sampleRow * columns + sampleColumn]
                            } else {
                                !keepsWhenAny
                            }
                            any = any || value
                            all = all && value
                        }
                        output[row * columns + column] = if (keepsWhenAny) any else all
                    }
                }
                return output
            }
            return sweep(sweep(mask, keepsWhenAny = true), keepsWhenAny = false)
        }

        val FOUR_WAYS = listOf(0 to 1, 1 to 0, 0 to -1, -1 to 0)
    }
}
