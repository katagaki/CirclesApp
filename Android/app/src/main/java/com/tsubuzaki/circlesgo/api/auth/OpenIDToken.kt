package com.tsubuzaki.circlesgo.api.auth

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OpenIDToken(
    @SerialName("access_token") val accessToken: String = "",
    @SerialName("token_type") val tokenType: String = "",
    @SerialName("expires_in") val expiresIn: String = "",
    @SerialName("refresh_token") val refreshToken: String = ""
)
