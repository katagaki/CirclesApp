package com.tsubuzaki.circlesgo.wayfinding

import com.tsubuzaki.circlesgo.state.ComiketHall

/**
 * How the ways into a hall are read off its map. The catalog has no entrances, and each
 * hall's map draws them differently.
 */
sealed class HallEntrances {
    /** Open gaps along the bottom edge of the map. */
    data class BottomEdge(val alignsStarts: Boolean, val requiresClearFloor: Boolean) : HallEntrances()

    /** The vestibules that join an open area outside the halls to the hall floor. */
    data object Vestibules : HallEntrances()

    /** One spot, as a fraction of the map's width and height. */
    data class Fixed(val x: Double, val y: Double) : HallEntrances()

    /**
     * The hall name plates on the edge of the map, for halls whose entrances have not been
     * checked yet.
     */
    data object Signs : HallEntrances()
}

val ComiketHall.entrances: HallEntrances
    get() = when (this) {
        ComiketHall.EAST_123 -> HallEntrances.BottomEdge(alignsStarts = true, requiresClearFloor = false)
        ComiketHall.EAST_7 -> HallEntrances.Fixed(x = 0.189, y = 0.956)
        ComiketHall.WEST_12 -> HallEntrances.Vestibules
        ComiketHall.SOUTH_12 -> HallEntrances.BottomEdge(alignsStarts = false, requiresClearFloor = true)
        ComiketHall.EAST_456, ComiketHall.EAST_78, ComiketHall.WEST_34, ComiketHall.SOUTH_34 -> HallEntrances.Signs
    }
