package com.tsubuzaki.circlesgo.wayfinding

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID
import kotlin.math.max
import kotlin.math.min

@Serializable
data class GridPoint(val row: Int, val column: Int)

/** A point in high-resolution map pixels. */
@Serializable
data class RoutePoint(val x: Double, val y: Double)

data class RouteRect(val x: Double, val y: Double, val width: Double, val height: Double) {
    val minX: Double get() = x
    val minY: Double get() = y
    val maxX: Double get() = x + width
    val maxY: Double get() = y + height
    val midX: Double get() = x + width / 2.0
    val midY: Double get() = y + height / 2.0

    fun insetBy(dx: Double, dy: Double): RouteRect =
        RouteRect(x + dx, y + dy, width - dx * 2.0, height - dy * 2.0)

    fun union(other: RouteRect): RouteRect {
        val left = min(minX, other.minX)
        val top = min(minY, other.minY)
        return RouteRect(left, top, max(maxX, other.maxX) - left, max(maxY, other.maxY) - top)
    }
}

/** A table on the hall map, in high-resolution map pixels. */
data class RouteTable(
    val rect: RouteRect,
    val blockName: String,
    val opensSideways: Boolean
)

/** A circle the route has to visit, in high-resolution map pixels. */
data class RouteStopRequest(
    val webCatalogID: Int,
    val circleID: Int,
    val name: String,
    val spaceName: String,
    val spaceRect: RouteRect,
    val opensSideways: Boolean,
    val rank: Int,
    val colorRawValue: Int
)

@Serializable
data class RouteStop(
    val id: Int,
    val circleID: Int,
    val name: String,
    val spaceName: String,
    val accessPoint: RoutePoint,
    val spaceCenter: RoutePoint,
    val colorRawValue: Int
)

@Serializable
enum class RouteTurn { LEFT, RIGHT, STRAIGHT }

@Serializable
enum class RouteSide { LEFT, RIGHT, AHEAD }

@Serializable
sealed class RoutePassage {
    @Serializable
    @SerialName("corridor")
    data object Corridor : RoutePassage()

    @Serializable
    @SerialName("corridorAlong")
    data class CorridorAlong(val block: String) : RoutePassage()

    @Serializable
    @SerialName("aisleBetween")
    data class AisleBetween(val left: String, val right: String) : RoutePassage()

    @Serializable
    @SerialName("aisleThrough")
    data class AisleThrough(val block: String) : RoutePassage()
}

@Serializable
sealed class RouteAction {
    @Serializable
    @SerialName("begin")
    data object Begin : RouteAction()

    @Serializable
    @SerialName("entrance")
    data class Entrance(val hall: String) : RouteAction()

    @Serializable
    @SerialName("exit")
    data class Exit(val hall: String) : RouteAction()

    @Serializable
    @SerialName("enter")
    data class Enter(val hall: String) : RouteAction()

    @Serializable
    @SerialName("turn")
    data class Turn(val turn: RouteTurn, val into: RoutePassage) : RouteAction()

    @Serializable
    @SerialName("arrive")
    data class Arrive(val side: RouteSide) : RouteAction()
}

@Serializable
data class RouteStep(
    val id: Int,
    val stopIndex: Int,
    val blocks: Int,
    val action: RouteAction,
    val path: List<RoutePoint>
) {
    /** The step that puts the visitor on the route, before they have walked any of it. */
    val isStart: Boolean
        get() = action is RouteAction.Begin || action is RouteAction.Entrance

    val isArrival: Boolean
        get() = action is RouteAction.Arrive || action is RouteAction.Begin
}

/** One hall of a map that spans several, such as East 1 within East 1–3. */
data class RouteHall(val name: String, val rect: RouteRect)

/**
 * A way in and out of the hall. `sign` is where the walk in starts; for halls still read
 * from their name plates it is the plate itself.
 */
data class RouteDoor(
    val cell: GridPoint,
    val sign: RouteRect,
    val edge: Edge,
    val isSign: Boolean = false
) {
    enum class Edge { TOP, BOTTOM, LEFT, RIGHT }
}

/**
 * A path staff have closed off, in high-resolution map pixels. Closures lapse on their
 * own, since a queue or crowd that closes an aisle rarely lasts.
 */
@Serializable
data class RouteClosure(
    val id: String,
    val point: RoutePoint,
    val across: GridPoint? = null,
    val hallBoundaryX: Double? = null,
    val expiresAt: Long
) {
    val isActive: Boolean get() = expiresAt > System.currentTimeMillis()

    companion object {
        const val LIFETIME_MILLIS: Long = 30L * 60L * 1000L

        fun create(
            point: RoutePoint,
            across: GridPoint? = null,
            hallBoundaryX: Double? = null,
            now: Long = System.currentTimeMillis()
        ): RouteClosure = RouteClosure(
            id = UUID.randomUUID().toString(),
            point = point,
            across = across,
            hallBoundaryX = hallBoundaryX,
            expiresAt = now + LIFETIME_MILLIS
        )
    }
}

@Serializable
data class RouteClosureLine(val id: String, val from: RoutePoint, val to: RoutePoint)

@Serializable
data class PlannedRoute(
    val stops: List<RouteStop>,
    val legs: List<List<RoutePoint>>,
    val steps: List<RouteStep>,
    val origin: RoutePoint?,
    val closures: List<RouteClosureLine>,
    val outsidePaths: List<List<RoutePoint>>,
    val skippedSpaces: List<String>
)
