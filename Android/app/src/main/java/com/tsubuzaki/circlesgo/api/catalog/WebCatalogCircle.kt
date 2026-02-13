package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class WebCatalogCircle(
    @SerialName("wcid") val webCatalogID: Int,
    val name: String,
    @SerialName("name_kana") val nameKana: String,
    @SerialName("circlemsId") val circlemsID: String,
    @SerialName("cut_url") val cutURL: String,
    @SerialName("cut_base_url") val cutBaseURL: String,
    @SerialName("cut_web_url") val cutWebURL: String,
    @SerialName("cut_web_updatedate") val cutWebUpdateDate: String,
    val genre: String,
    val url: String,
    @SerialName("pixiv_url") val pixivURL: String,
    @SerialName("twitter_url") val twitterURL: String,
    @SerialName("clipstudio_url") val clipStudioURL: String,
    @SerialName("niconico_url") val niconicoURL: String,
    val tag: String,
    @SerialName("description") val circleDescription: String,
    @SerialName("onlinestore") val onlineStores: List<OnlineStore>,
    @SerialName("updateId") val updateID: String,
    @SerialName("update_date") val updateDate: String
) {
    @Serializable
    data class OnlineStore(
        val name: String,
        val link: String
    )
}
