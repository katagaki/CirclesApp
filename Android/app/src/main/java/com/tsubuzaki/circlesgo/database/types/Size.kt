package com.tsubuzaki.circlesgo.database.types

import kotlinx.serialization.Serializable

@Serializable
data class Size(
    val width: Int,
    val height: Int
)
