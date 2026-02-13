package com.tsubuzaki.circlesgo.database.types

import kotlinx.serialization.Serializable

@Serializable
data class CircleCutConfiguration(
    val size: Size,
    val origin: Point,
    val offset: Point
)
