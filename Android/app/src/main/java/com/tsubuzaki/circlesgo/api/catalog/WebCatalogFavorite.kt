package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class WebCatalogFavorite(
    @SerialName("wcid") val webCatalogID: Int,
    @SerialName("circle_name") val circleName: String,
    val color: Int,
    val memo: String? = null,
    val free: String? = null,
    @SerialName("update_date") val updateDate: String
) {
    fun webCatalogColor(): WebCatalogColor? = WebCatalogColor.fromValue(color)

    @Serializable
    data class Request(
        @SerialName("wcid") val webCatalogID: Int,
        val color: Int,
        val memo: String
    )
}
