package com.tsubuzaki.circlesgo.wayfinding

/** A growable stack of ints, so flood fills over millions of pixels do not box each one. */
internal class IntStack(capacity: Int = 1024) {

    private var values = IntArray(capacity)
    var size: Int = 0
        private set

    fun isEmpty(): Boolean = size == 0

    fun push(value: Int) {
        if (size == values.size) values = values.copyOf(size * 2)
        values[size++] = value
    }

    fun pop(): Int = values[--size]
}
