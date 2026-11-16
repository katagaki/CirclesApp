package com.tsubuzaki.circlesgo.state

import android.content.Context
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.database.tables.ComiketCircle
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class FavoritesFilters(context: Context) {

    companion object {
        private const val PREFS_NAME = "circles_prefs"
        private const val FILTERED_COLORS_KEY = "Favorites.FilteredColors"
        private const val FILTERED_HALLS_KEY = "Favorites.FilteredHalls"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _colors = MutableStateFlow(loadIDs(FILTERED_COLORS_KEY))
    val colors: StateFlow<Set<Int>> = _colors

    private val _halls = MutableStateFlow(loadIDs(FILTERED_HALLS_KEY))
    val halls: StateFlow<Set<Int>> = _halls

    private val _hasUncoloredFavorites = MutableStateFlow(false)
    val hasUncoloredFavorites: StateFlow<Boolean> = _hasUncoloredFavorites

    private val _mapIDsByBlockID = MutableStateFlow<Map<Int, Int>>(emptyMap())
    val mapIDsByBlockID: StateFlow<Map<Int, Int>> = _mapIDsByBlockID

    fun toggleColor(color: Int) {
        setColors(_colors.value.toggled(color))
    }

    fun setColors(colors: Set<Int>) {
        _colors.value = colors
        saveIDs(FILTERED_COLORS_KEY, colors)
    }

    fun toggleHall(mapID: Int) {
        setHalls(_halls.value.toggled(mapID))
    }

    fun setHalls(halls: Set<Int>) {
        _halls.value = halls
        saveIDs(FILTERED_HALLS_KEY, halls)
    }

    fun setHasUncoloredFavorites(hasUncoloredFavorites: Boolean) {
        _hasUncoloredFavorites.value = hasUncoloredFavorites
    }

    fun setMapIDsByBlockID(mapIDsByBlockID: Map<Int, Int>) {
        _mapIDsByBlockID.value = mapIDsByBlockID
    }

    fun filtered(
        groups: Map<String, List<ComiketCircle>>,
        colors: Set<Int>,
        halls: Set<Int>,
        mapIDsByBlockID: Map<Int, Int>
    ): Map<String, List<ComiketCircle>> {
        if (colors.isEmpty() && halls.isEmpty()) return groups
        val results = mutableMapOf<String, List<ComiketCircle>>()
        for ((colorKey, circles) in groups) {
            if (colors.isNotEmpty() && (colorKey.toIntOrNull() ?: -1) !in colors) continue
            results[colorKey] = if (halls.isEmpty()) {
                circles
            } else {
                circles.filter { circle -> mapIDsByBlockID[circle.blockID]?.let { it in halls } == true }
            }
        }
        return results
    }

    private fun Set<Int>.toggled(id: Int): Set<Int> = if (id in this) this - id else this + id

    private fun loadIDs(key: String): Set<Int> =
        prefs.getStringSet(key, null)?.mapNotNull { it.toIntOrNull() }?.toSet() ?: emptySet()

    private fun saveIDs(key: String, ids: Set<Int>) {
        prefs.edit { putStringSet(key, ids.map { it.toString() }.toSet()) }
    }
}
