package com.tsubuzaki.circlesgo.state

enum class CircleDisplayMode(val value: Int) {
    GRID(1),
    LIST(2)
}

enum class GridDisplayMode(val value: Int) {
    BIG(1),
    MEDIUM(2),
    SMALL(3)
}

enum class ListDisplayMode(val value: Int) {
    REGULAR(1),
    COMPACT(2)
}

enum class MapAutoScrollType(val value: Int) {
    NONE(0),
    POPOVER(1)
}
