package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class UserCircle(
    val status: String,
    val response: Response
) {
    @Serializable
    data class Response(
        val count: Int,
        val circles: List<Circle>
    ) {
        @Serializable
        data class Circle(
            @SerialName("EventId") val eventID: Int,
            @SerialName("wcid") val webCatalogID: Int,
            @SerialName("circlemsId") val circleMsID: Int,
            val name: String
        )
    }
}
