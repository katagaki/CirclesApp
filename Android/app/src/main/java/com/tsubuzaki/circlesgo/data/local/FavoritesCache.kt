package com.tsubuzaki.circlesgo.data.local

import android.content.Context
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.api.catalog.UserFavorites
import kotlinx.serialization.json.Json

class FavoritesCache(context: Context) {

    companion object {
        private const val PREFS_NAME = "circles_favorites_cache"
        private const val FAVORITES_KEY = "cached_favorites"
        private val json = Json { ignoreUnknownKeys = true }
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun save(items: List<UserFavorites.Response.FavoriteItem>) {
        val encoded = json.encodeToString(items)
        prefs.edit { putString(FAVORITES_KEY, encoded) }
    }

    fun load(): List<UserFavorites.Response.FavoriteItem> {
        val encoded = prefs.getString(FAVORITES_KEY, null) ?: return emptyList()
        return try {
            json.decodeFromString(encoded)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun clear() {
        prefs.edit { remove(FAVORITES_KEY) }
    }
}
