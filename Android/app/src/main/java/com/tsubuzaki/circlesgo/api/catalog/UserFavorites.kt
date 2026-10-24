package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class UserFavorites(
    val status: String,
    val response: Response
) {
    @Serializable
    data class Response(
        val count: Int,
        @SerialName("maxcount") val maxCount: Int,
        val list: List<FavoriteItem>
    ) {
        @Serializable
        data class FavoriteItem(
            val circle: WebCatalogCircle,
            val favorite: WebCatalogFavorite
        )
    }
}
