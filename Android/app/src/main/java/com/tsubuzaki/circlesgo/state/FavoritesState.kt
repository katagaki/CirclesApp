package com.tsubuzaki.circlesgo.state

import com.tsubuzaki.circlesgo.api.catalog.UserFavorites
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogColor
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext

class FavoritesState {

    private val _items = MutableStateFlow<List<UserFavorites.Response.FavoriteItem>?>(null)
    val items: StateFlow<List<UserFavorites.Response.FavoriteItem>?> = _items

    private val _wcIDMappedItems =
        MutableStateFlow<Map<Int, UserFavorites.Response.FavoriteItem>?>(null)
    val wcIDMappedItems: StateFlow<Map<Int, UserFavorites.Response.FavoriteItem>?> =
        _wcIDMappedItems

    private val _circles = MutableStateFlow<Map<String, List<ComiketCircle>>?>(null)
    val circles: StateFlow<Map<String, List<ComiketCircle>>?> = _circles

    var invalidationID: String = ""

    fun setItems(items: List<UserFavorites.Response.FavoriteItem>) {
        _items.value = items
    }

    fun setWcIDMappedItems(items: Map<Int, UserFavorites.Response.FavoriteItem>) {
        _wcIDMappedItems.value = items
    }

    fun setCircles(circles: Map<String, List<ComiketCircle>>) {
        _circles.value = circles
    }

    fun reset() {
        _items.value = null
        _wcIDMappedItems.value = null
        _circles.value = null
        invalidationID = ""
    }

    fun contains(webCatalogID: Int): Boolean {
        return _items.value?.any { it.circle.webCatalogID == webCatalogID } == true
    }

    companion object {
        suspend fun mapped(
            favoriteItems: List<UserFavorites.Response.FavoriteItem>,
            database: CatalogDatabase
        ): Map<Int, List<Int>> = withContext(Dispatchers.IO) {
            // Group favorite items by color, normalizing unknown colors
            val groupedByColor = favoriteItems.groupBy {
                WebCatalogColor.fromValue(it.favorite.color).value
            }

            val fetcher = DataFetcher(database.getTextDatabase())
            val result = mutableMapOf<Int, List<Int>>()

            for ((colorKey, items) in groupedByColor) {
                val webCatalogIDs = items.map { it.circle.webCatalogID }
                val circleIDs = fetcher.circlesWithWebCatalogIDs(webCatalogIDs)
                result[colorKey] = circleIDs
            }
            result
        }
    }
}
