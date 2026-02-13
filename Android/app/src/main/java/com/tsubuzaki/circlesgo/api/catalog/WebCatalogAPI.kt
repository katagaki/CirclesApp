package com.tsubuzaki.circlesgo.api.catalog

import android.content.Context
import android.util.Log
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.api.Endpoints
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

object WebCatalogAPI {

    private const val TAG = "WebCatalogAPI"
    private const val EVENT_CACHE_KEY = "WebCatalog.Events"
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun events(
        authToken: OpenIDToken,
        context: Context
    ): WebCatalogEvent.Response? = withContext(Dispatchers.IO) {
        try {
            val connection = urlRequestForWebCatalogAPI("GetEventList", authToken = authToken)
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                val events = json.decodeFromString(WebCatalogEvent.serializer(), responseBody)
                // Cache the response
                val prefs = context.getSharedPreferences("circles_prefs", Context.MODE_PRIVATE)
                prefs.edit { putString(EVENT_CACHE_KEY, responseBody) }
                events.response
            } else {
                Log.e(TAG, "Failed to fetch events: HTTP $responseCode")
                // Attempt to load from cache
                loadCachedEvents(context)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch events", e)
            loadCachedEvents(context)
        }
    }

    private fun loadCachedEvents(context: Context): WebCatalogEvent.Response? {
        val prefs = context.getSharedPreferences("circles_prefs", Context.MODE_PRIVATE)
        val cachedData = prefs.getString(EVENT_CACHE_KEY, null) ?: return null
        return try {
            val events = json.decodeFromString(WebCatalogEvent.serializer(), cachedData)
            events.response
        } catch (e: Exception) {
            null
        }
    }

    suspend fun circle(
        webCatalogID: Int,
        authToken: OpenIDToken
    ): UserCircleWithFavorite? = withContext(Dispatchers.IO) {
        try {
            val connection = urlRequestForWebCatalogAPI(
                "GetCircle",
                parameters = mapOf("wcid" to webCatalogID.toString()),
                authToken = authToken
            )
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                json.decodeFromString(UserCircleWithFavorite.serializer(), responseBody)
            } else {
                Log.e(TAG, "Failed to fetch circle: HTTP $responseCode")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch circle", e)
            null
        }
    }

    private fun urlRequestForWebCatalogAPI(
        endpoint: String,
        parameters: Map<String, String> = emptyMap(),
        authToken: OpenIDToken
    ): HttpURLConnection {
        val baseURL = "${Endpoints.circleMsAPIEndpoint}/WebCatalog/$endpoint"
        val urlString = if (parameters.isNotEmpty()) {
            val queryString = parameters.entries.joinToString("&") { (key, value) ->
                "$key=${URLEncoder.encode(value, "UTF-8")}"
            }
            "$baseURL?$queryString"
        } else {
            baseURL
        }

        val url = URL(urlString)
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Authorization", "Bearer ${authToken.accessToken}")
        connection.connectTimeout = 2000
        return connection
    }
}
