package com.tsubuzaki.circlesgo.database.types

enum class LayoutType(val value: Int) {
    A_ON_LEFT(1),
    A_ON_BOTTOM(2),
    A_ON_RIGHT(3),
    A_ON_TOP(4),
    UNKNOWN(-1);

    companion object {
        fun fromValue(value: Int): LayoutType {
            return entries.find { it.value == value } ?: UNKNOWN
        }
    }
}
