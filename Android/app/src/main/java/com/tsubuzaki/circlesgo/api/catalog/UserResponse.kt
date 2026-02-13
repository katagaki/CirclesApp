package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.Serializable

@Serializable
data class UserResponse(
    val status: String,
    val response: Response? = null
) {
    @Serializable
    data class Response(
        val circle: WebCatalogCircle? = null,
        val favorite: WebCatalogFavorite? = null
    )
}
