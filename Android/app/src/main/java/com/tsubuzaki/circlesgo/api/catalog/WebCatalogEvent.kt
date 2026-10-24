package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class WebCatalogEvent(
    val status: String,
    val response: Response
) {
    @Serializable
    data class Response(
        val list: List<Event>,
        @SerialName("LatestEventId") val latestEventID: Int,
        @SerialName("LatestEventNo") val latestEventNumber: Int
    ) {
        @Serializable
        data class Event(
            @SerialName("EventId") val id: Int,
            @SerialName("EventNo") val number: Int
        )
    }
}
