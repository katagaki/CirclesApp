package com.tsubuzaki.circlesgo.api.catalog

import kotlinx.serialization.Serializable

@Serializable
data class UserInfo(
    val status: String,
    val response: Response
) {
    @Serializable
    data class Response(
        val pid: Int,
        val r18: Int,
        val nickname: String
    )
}
