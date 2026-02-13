package com.tsubuzaki.circlesgo.state

enum class ComiketHall(val value: String) {
    EAST_123("E123"),
    EAST_456("E456"),
    EAST_7("E7"),
    EAST_78("E78"),
    WEST_12("W12"),
    WEST_34("W34"),
    SOUTH_12("S12"),
    SOUTH_34("S34");

    companion object {
        fun fromValue(value: String): ComiketHall? {
            return entries.find { it.value == value }
        }
    }
}
