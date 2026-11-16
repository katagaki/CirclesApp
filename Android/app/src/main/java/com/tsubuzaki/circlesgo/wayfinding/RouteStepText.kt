package com.tsubuzaki.circlesgo.wayfinding

import android.content.Context
import com.tsubuzaki.circlesgo.R

fun RouteStep.instruction(context: Context, stop: RouteStop): String {
    val resources = context.resources
    val walk = if (blocks > 0) {
        resources.getQuantityString(R.plurals.route_walk_blocks, blocks, blocks)
    } else {
        context.getString(R.string.route_walk_ahead)
    }
    return when (val action = action) {
        is RouteAction.Begin -> context.getString(R.string.route_begin, stop.spaceName)
        is RouteAction.Entrance -> if (action.hall.isEmpty()) {
            context.getString(R.string.route_entrance)
        } else {
            context.getString(R.string.route_entrance_hall, action.hall)
        }
        is RouteAction.Exit -> context.getString(R.string.route_exit, walk, action.hall)
        is RouteAction.Enter -> context.getString(R.string.route_enter, action.hall)
        is RouteAction.Turn -> {
            val into = action.into.name(context)
            when (action.turn) {
                RouteTurn.LEFT -> context.getString(R.string.route_turn_left, walk, into)
                RouteTurn.RIGHT -> context.getString(R.string.route_turn_right, walk, into)
                RouteTurn.STRAIGHT -> context.getString(R.string.route_turn_straight, walk, into)
            }
        }
        is RouteAction.Arrive -> when (action.side) {
            RouteSide.LEFT -> context.getString(R.string.route_arrive_left, walk, stop.spaceName)
            RouteSide.RIGHT -> context.getString(R.string.route_arrive_right, walk, stop.spaceName)
            RouteSide.AHEAD -> context.getString(R.string.route_arrive_ahead, walk, stop.spaceName)
        }
    }
}

fun RoutePassage.name(context: Context): String = when (this) {
    is RoutePassage.Corridor -> context.getString(R.string.route_passage_corridor)
    is RoutePassage.CorridorAlong -> context.getString(R.string.route_passage_corridor_along, block)
    is RoutePassage.AisleBetween -> context.getString(R.string.route_passage_aisle_between, left, right)
    is RoutePassage.AisleThrough -> context.getString(R.string.route_passage_aisle_through, block)
}
