package com.tsubuzaki.circlesgo.api.catalog

import android.util.Log
import com.tsubuzaki.circlesgo.api.Endpoints
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.net.HttpURLConnection
import java.net.URL

object UserAPI {

    private const val TAG = "UserAPI"
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun info(authToken: OpenIDToken): UserInfo.Response? = withContext(Dispatchers.IO) {
        try {
            val connection = urlRequestForUserAPI("Info", authToken)
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                val userInfo = json.decodeFromString(UserInfo.serializer(), responseBody)
                userInfo.response
            } else {
                Log.e(TAG, "Failed to fetch user info: HTTP $responseCode")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch user info", e)
            null
        }
    }

    suspend fun events(authToken: OpenIDToken): List<UserCircle.Response.Circle> =
        withContext(Dispatchers.IO) {
            try {
                val connection = urlRequestForUserAPI("Circles", authToken)
                val responseCode = connection.responseCode
                if (responseCode == HttpURLConnection.HTTP_OK) {
                    val responseBody = connection.inputStream.bufferedReader().readText()
                    val userCircles = json.decodeFromString(UserCircle.serializer(), responseBody)
                    userCircles.response.circles
                } else {
                    Log.e(TAG, "Failed to fetch user events: HTTP $responseCode")
                    emptyList()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to fetch user events", e)
                emptyList()
            }
        }

    private fun urlRequestForUserAPI(endpoint: String, authToken: OpenIDToken): HttpURLConnection {
        val url = URL("${Endpoints.circleMsAPIEndpoint}/User/$endpoint/")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Authorization", "Bearer ${authToken.accessToken}")
        return connection
    }
}
