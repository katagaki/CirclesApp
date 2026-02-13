package com.tsubuzaki.circlesgo.database.types

import kotlinx.serialization.Serializable

@Serializable
data class MapConfiguration(
    val size: Size,
    val origin: Point
)
