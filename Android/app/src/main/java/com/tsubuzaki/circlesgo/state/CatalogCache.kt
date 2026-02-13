package com.tsubuzaki.circlesgo.state

import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.DataFetcher
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class CatalogCache {

    private val _displayedCircles = MutableStateFlow<List<ComiketCircle>>(emptyList())
    val displayedCircles: StateFlow<List<ComiketCircle>> = _displayedCircles

    private val _searchedCircles = MutableStateFlow<List<ComiketCircle>?>(null)
    val searchedCircles: StateFlow<List<ComiketCircle>?> = _searchedCircles

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    var invalidationID: String = ""

    val hasMoreDisplayedCircles: Boolean
        get() = _displayedCircles.value.size < allFilterResultIDs.size

    val hasMoreSearchedCircles: Boolean
        get() = _searchedCircles.value?.let { it.size < (allSearchResultIDs?.size ?: 0) } ?: false

    private var allFilterResultIDs: List<Int> = emptyList()
    private var allSearchResultIDs: List<Int>? = null
    private val pageSize = 50

    fun setDisplayedCircles(circles: List<ComiketCircle>, allIDs: List<Int>) {
        allFilterResultIDs = allIDs
        _displayedCircles.value = circles
    }

    fun setSearchedCircles(circles: List<ComiketCircle>?, allIDs: List<Int>?) {
        allSearchResultIDs = allIDs
        _searchedCircles.value = circles
    }

    fun loadMoreDisplayedCircles(database: CatalogDatabase) {
        val currentCount = _displayedCircles.value.size
        if (currentCount >= allFilterResultIDs.size) return

        val nextIDs = allFilterResultIDs.drop(currentCount).take(pageSize)
        database.prefetchCircleImages(nextIDs)
        val nextCircles = database.circles(nextIDs)
        if (nextCircles.isNotEmpty()) {
            _displayedCircles.value = _displayedCircles.value + nextCircles
        }
    }

    fun loadMoreSearchedCircles(database: CatalogDatabase) {
        val searchIDs = allSearchResultIDs ?: return
        val currentCircles = _searchedCircles.value ?: return
        val currentCount = currentCircles.size
        if (currentCount >= searchIDs.size) return

        val nextIDs = searchIDs.drop(currentCount).take(pageSize)
        database.prefetchCircleImages(nextIDs)
        val nextCircles = database.circles(nextIDs)
        if (nextCircles.isNotEmpty()) {
            _searchedCircles.value = currentCircles + nextCircles
        }
    }

    fun setIsLoading(loading: Boolean) {
        _isLoading.value = loading
    }

    companion object {
        suspend fun fetchCircles(
            genreIDs: List<Int>?,
            mapID: Int?,
            blockIDs: List<Int>?,
            dayID: Int?,
            database: CatalogDatabase
        ): List<Int> {
            val fetcher = DataFetcher(database.getTextDatabase())
            return fetcher.circles(
                mapID = mapID,
                genreIDs = genreIDs,
                blockIDs = blockIDs,
                dayID = dayID
            )
        }

        suspend fun fetchGenreIDs(
            mapID: Int,
            dayID: Int,
            database: CatalogDatabase
        ): List<Int> {
            val fetcher = DataFetcher(database.getTextDatabase())
            return fetcher.genreIDs(mapID, dayID)
        }

        suspend fun fetchBlockIDs(
            mapID: Int,
            dayID: Int,
            genreIDs: List<Int>?,
            database: CatalogDatabase
        ): List<Int> {
            val fetcher = DataFetcher(database.getTextDatabase())
            return fetcher.blockIDs(mapID, dayID, genreIDs)
        }

        suspend fun searchCircles(
            searchTerm: String,
            database: CatalogDatabase
        ): List<Int>? {
            val fetcher = DataFetcher(database.getTextDatabase())
            val trimmed = searchTerm.trim()
            return if (trimmed.length >= 2) {
                fetcher.circlesContaining(trimmed)
            } else {
                null
            }
        }
    }
}
