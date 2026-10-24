package com.tsubuzaki.circlesgo.api.auth

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OpenIDClient(
    @SerialName("client_id") val id: String,
    @SerialName("client_secret") val secret: String,
    @SerialName("redirect_url") val redirectURL: String
)
