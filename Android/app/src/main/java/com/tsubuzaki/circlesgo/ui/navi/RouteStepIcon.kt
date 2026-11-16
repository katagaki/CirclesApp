package com.tsubuzaki.circlesgo.ui.navi

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.Login
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.TurnLeft
import androidx.compose.material.icons.filled.TurnRight
import androidx.compose.material.icons.filled.DoorFront
import androidx.compose.material.icons.filled.PinDrop
import androidx.compose.material.icons.filled.Straight
import androidx.compose.ui.graphics.vector.ImageVector
import com.tsubuzaki.circlesgo.wayfinding.RouteAction
import com.tsubuzaki.circlesgo.wayfinding.RouteStep
import com.tsubuzaki.circlesgo.wayfinding.RouteTurn

val RouteStep.icon: ImageVector
    get() = when (val action = action) {
        is RouteAction.Turn -> when (action.turn) {
            RouteTurn.LEFT -> Icons.Filled.TurnLeft
            RouteTurn.RIGHT -> Icons.Filled.TurnRight
            RouteTurn.STRAIGHT -> Icons.Filled.Straight
        }
        is RouteAction.Arrive -> Icons.Filled.PinDrop
        is RouteAction.Begin -> Icons.AutoMirrored.Filled.DirectionsWalk
        is RouteAction.Entrance -> Icons.Filled.DoorFront
        is RouteAction.Exit -> Icons.AutoMirrored.Filled.Logout
        is RouteAction.Enter -> Icons.AutoMirrored.Filled.Login
    }
