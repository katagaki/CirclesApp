package com.tsubuzaki.circlesgo.state

import android.content.Context
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.tables.ComiketBlock
import com.tsubuzaki.circlesgo.database.tables.ComiketDate
import com.tsubuzaki.circlesgo.database.tables.ComiketGenre
import com.tsubuzaki.circlesgo.database.tables.ComiketMap
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class UserSelections(context: Context) {

    companion object {
        private const val PREFS_NAME = "circles_prefs"
        private const val SELECTED_DATE_KEY = "Circles.SelectedDateID"
        private const val SELECTED_MAP_KEY = "Circles.SelectedMapID"
        private const val SELECTED_BLOCKS_KEY = "Circles.SelectedBlockIDs"
        private const val SELECTED_GENRES_KEY = "Circles.SelectedGenreIDs"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _date = MutableStateFlow<ComiketDate?>(null)
    val date: StateFlow<ComiketDate?> = _date

    private val _map = MutableStateFlow<ComiketMap?>(null)
    val map: StateFlow<ComiketMap?> = _map

    private val _blocks = MutableStateFlow<Set<ComiketBlock>>(emptySet())
    val blocks: StateFlow<Set<ComiketBlock>> = _blocks

    private val _genres = MutableStateFlow<Set<ComiketGenre>>(emptySet())
    val genres: StateFlow<Set<ComiketGenre>> = _genres

    fun setDate(date: ComiketDate?) {
        if (_date.value != date) {
            _date.value = date
            prefs.edit().putInt(SELECTED_DATE_KEY, date?.id ?: 0).apply()
            _genres.value = emptySet()
            prefs.edit().putStringSet(SELECTED_GENRES_KEY, emptySet()).apply()
            _blocks.value = emptySet()
            prefs.edit { putStringSet(SELECTED_BLOCKS_KEY, emptySet()) }
        }
    }

    fun setMap(map: ComiketMap?) {
        if (_map.value != map) {
            _map.value = map
            prefs.edit { putInt(SELECTED_MAP_KEY, map?.id ?: 0) }
            _genres.value = emptySet()
            prefs.edit { putStringSet(SELECTED_GENRES_KEY, emptySet()) }
            _blocks.value = emptySet()
            prefs.edit { putStringSet(SELECTED_BLOCKS_KEY, emptySet()) }
        }
    }

    fun setBlocks(blocks: Set<ComiketBlock>) {
        _blocks.value = blocks
        prefs.edit {
            putStringSet(SELECTED_BLOCKS_KEY, blocks.map { it.id.toString() }.toSet())
        }
    }

    fun setGenres(genres: Set<ComiketGenre>) {
        _genres.value = genres
        prefs.edit {
            putStringSet(SELECTED_GENRES_KEY, genres.map { it.id.toString() }.toSet())
        }
    }

    fun reloadData(database: CatalogDatabase) {
        val dateID = prefs.getInt(SELECTED_DATE_KEY, 0)
        val mapID = prefs.getInt(SELECTED_MAP_KEY, 0)
        _date.value = database.dates().firstOrNull { it.id == dateID }
        _map.value = database.maps().firstOrNull { it.id == mapID }

        val blockIDs =
            prefs.getStringSet(SELECTED_BLOCKS_KEY, emptySet())?.mapNotNull { it.toIntOrNull() }
                ?: emptyList()
        val genreIDs =
            prefs.getStringSet(SELECTED_GENRES_KEY, emptySet())?.mapNotNull { it.toIntOrNull() }
                ?: emptyList()
        _blocks.value = database.blocks().filter { it.id in blockIDs }.toSet()
        _genres.value = database.genres().filter { it.id in genreIDs }.toSet()
    }

    fun fetchDefaultDateSelection(database: CatalogDatabase): ComiketDate? {
        return database.dates().firstOrNull()
    }

    fun fetchDefaultMapSelection(database: CatalogDatabase): ComiketMap? {
        return database.maps().firstOrNull()
    }

    val fullMapID: String
        get() = "M${_map.value?.id ?: -1},D${_date.value?.id ?: -1}"

    val catalogSelectionID: String
        get() {
            val genreIDs = _genres.value.map { it.id.toString() }.sorted().joinToString("-")
            val blockIDs = _blocks.value.map { it.id.toString() }.sorted().joinToString("-")
            return "M${_map.value?.id ?: -1},D${_date.value?.id ?: -1},G[$genreIDs],B[$blockIDs]"
        }

    fun resetSelections() {
        prefs.edit {
            putInt(SELECTED_DATE_KEY, 0)
                .putInt(SELECTED_MAP_KEY, 0)
                .putStringSet(SELECTED_GENRES_KEY, emptySet())
                .putStringSet(SELECTED_BLOCKS_KEY, emptySet())
        }
        _genres.value = emptySet()
        _blocks.value = emptySet()
    }
}
