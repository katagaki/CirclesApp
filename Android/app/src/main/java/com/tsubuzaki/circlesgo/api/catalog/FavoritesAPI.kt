package com.tsubuzaki.circlesgo.api.catalog

import android.util.Log
import com.tsubuzaki.circlesgo.api.Endpoints
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import com.tsubuzaki.circlesgo.data.local.FavoritesCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

class FavoritesAPI(private val cache: FavoritesCache) {

    companion object {
        private const val TAG = "FavoritesAPI"
        private val json = Json { ignoreUnknownKeys = true }
    }

    suspend fun all(authToken: OpenIDToken): Pair<
            List<UserFavorites.Response.FavoriteItem>,
            Map<Int, UserFavorites.Response.FavoriteItem>
            > = withContext(Dispatchers.IO) {
        try {
            val connection = urlRequestForReadersAPI("FavoriteCircles", authToken = authToken)
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                val favorites = json.decodeFromString(UserFavorites.serializer(), responseBody)
                val items = favorites.response.list.sortedBy { it.favorite.color }
                val wcIDMappedItems = items.associateBy { it.circle.webCatalogID }

                // Cache locally
                cache.save(items)

                Pair(items, wcIDMappedItems)
            } else {
                Log.e(TAG, "Failed to fetch favorites: HTTP $responseCode")
                loadCachedFavorites()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to fetch favorites", e)
            loadCachedFavorites()
        }
    }

    private fun loadCachedFavorites(): Pair<
            List<UserFavorites.Response.FavoriteItem>,
            Map<Int, UserFavorites.Response.FavoriteItem>
            > {
        val items = cache.load()
        val wcIDMappedItems = items.associateBy { it.circle.webCatalogID }
        return Pair(items, wcIDMappedItems)
    }

    suspend fun add(
        webCatalogID: Int,
        color: WebCatalogColor,
        memo: String = "",
        authToken: OpenIDToken
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val params = mapOf(
                "access_token" to authToken.accessToken,
                "wcid" to webCatalogID.toString(),
                "color" to color.value.toString(),
                "memo" to memo
            )
            val connection =
                urlRequestForReadersAPI("Favorite", parameters = params, authToken = authToken)
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                val response =
                    json.decodeFromString(UserCircleWithFavorite.serializer(), responseBody)
                if (response.status == "success") {
                    val circle = response.response.circle
                    val favorite = response.response.favorite
                    if (circle != null && favorite != null) {
                        val item = UserFavorites.Response.FavoriteItem(
                            circle = circle,
                            favorite = favorite
                        )
                        val cached = cache.load().toMutableList()
                        cached.removeAll { it.circle.webCatalogID == webCatalogID }
                        cached.add(item)
                        cache.save(cached)
                    }
                    true
                } else {
                    false
                }
            } else {
                Log.e(TAG, "Failed to add favorite: HTTP $responseCode")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add favorite", e)
            false
        }
    }

    suspend fun delete(
        webCatalogID: Int,
        authToken: OpenIDToken
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val params = mapOf(
                "access_token" to authToken.accessToken,
                "wcid" to webCatalogID.toString()
            )
            val connection = urlRequestForReadersAPI(
                "Favorite",
                method = "DELETE",
                parameters = params,
                authToken = authToken
            )
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val responseBody = connection.inputStream.bufferedReader().readText()
                val response = json.decodeFromString(UserResponse.serializer(), responseBody)
                if (response.status == "success") {
                    val cached = cache.load().toMutableList()
                    cached.removeAll { it.circle.webCatalogID == webCatalogID }
                    cache.save(cached)
                    true
                } else {
                    false
                }
            } else {
                Log.e(TAG, "Failed to delete favorite: HTTP $responseCode")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to delete favorite", e)
            false
        }
    }

    private fun urlRequestForReadersAPI(
        endpoint: String,
        method: String = "POST",
        parameters: Map<String, String> = emptyMap(),
        authToken: OpenIDToken
    ): HttpURLConnection {
        val baseURL = "${Endpoints.circleMsAPIEndpoint}/Readers/$endpoint"
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
        connection.requestMethod = method
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Authorization", "Bearer ${authToken.accessToken}")
        return connection
    }
}
