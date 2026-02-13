package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.Serializable

@Serializable
data class UserCircleWithFavorite(
    val status: String,
    val response: Response
) {
    @Serializable
    data class Response(
        val circle: WebCatalogCircle? = null,
        val favorite: WebCatalogFavorite? = null
    )
}
