package com.tsubuzaki.circlesgo.database.types

import kotlinx.serialization.Serializable

@Serializable
data class Point(
    val x: Int,
    val y: Int
)
