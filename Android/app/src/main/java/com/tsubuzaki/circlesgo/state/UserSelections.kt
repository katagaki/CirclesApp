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
        private const val SHOW_GENRE_OVERLAY_KEY = "Circles.ShowGenreOverlay"
        private const val PRIVACY_MODE_KEY = "Circles.PrivacyMode"
        private const val CIRCLE_DISPLAY_MODE_KEY = "Circles.DisplayMode"
        private const val SHOW_SPACE_NAME_KEY = "Circles.ShowSpaceName"
        private const val SHOW_DAY_KEY = "Circles.ShowDay"
        private const val DARKEN_MAP_IN_DARK_MODE_KEY = "Circles.DarkenMapInDarkMode"
        private const val USE_HIGH_RESOLUTION_MAPS_KEY = "Circles.UseHighResolutionMaps"
        private const val MAP_ZOOM_LEVEL_KEY = "Circles.MapZoomLevel"
        private const val SHOW_WEB_CUTS_KEY = "Circles.ShowWebCuts"
        private const val GRID_SIZE_KEY = "Circles.GridSize"
        private const val LIST_SIZE_KEY = "Circles.ListSize"
        private const val FAVORITES_DISPLAY_MODE_KEY = "Favorites.DisplayMode"
        private const val FAVORITES_GROUP_BY_COLOR_KEY = "Favorites.GroupByColor"
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

    private val _showGenreOverlay = MutableStateFlow(
        prefs.getBoolean(SHOW_GENRE_OVERLAY_KEY, false)
    )
    val showGenreOverlay: StateFlow<Boolean> = _showGenreOverlay

    private val _isPrivacyMode = MutableStateFlow(
        prefs.getBoolean(PRIVACY_MODE_KEY, false)
    )
    val isPrivacyMode: StateFlow<Boolean> = _isPrivacyMode

    private val _showSpaceName = MutableStateFlow(
        prefs.getBoolean(SHOW_SPACE_NAME_KEY, false)
    )
    val showSpaceName: StateFlow<Boolean> = _showSpaceName

    private val _showDay = MutableStateFlow(
        prefs.getBoolean(SHOW_DAY_KEY, false)
    )
    val showDay: StateFlow<Boolean> = _showDay

    private val _darkenMapInDarkMode = MutableStateFlow(
        prefs.getBoolean(DARKEN_MAP_IN_DARK_MODE_KEY, true)
    )
    val darkenMapInDarkMode: StateFlow<Boolean> = _darkenMapInDarkMode

    private val _useHighResolutionMaps = MutableStateFlow(
        prefs.getBoolean(USE_HIGH_RESOLUTION_MAPS_KEY, true)
    )
    val useHighResolutionMaps: StateFlow<Boolean> = _useHighResolutionMaps

    private val _mapZoomLevel = MutableStateFlow(
        prefs.getFloat(MAP_ZOOM_LEVEL_KEY, 1.0f)
    )
    val mapZoomLevel: StateFlow<Float> = _mapZoomLevel

    private val _showWebCuts = MutableStateFlow(
        prefs.getBoolean(SHOW_WEB_CUTS_KEY, false)
    )
    val showWebCuts: StateFlow<Boolean> = _showWebCuts

    private val _displayMode = MutableStateFlow(
        CircleDisplayMode.entries.find {
            it.value == prefs.getInt(CIRCLE_DISPLAY_MODE_KEY, CircleDisplayMode.GRID.value)
        } ?: CircleDisplayMode.GRID
    )
    val displayMode: StateFlow<CircleDisplayMode> = _displayMode

    private val _gridSize = MutableStateFlow(
        GridDisplayMode.entries.find {
            it.value == prefs.getInt(GRID_SIZE_KEY, GridDisplayMode.MEDIUM.value)
        } ?: GridDisplayMode.MEDIUM
    )
    val gridSize: StateFlow<GridDisplayMode> = _gridSize

    private val _listSize = MutableStateFlow(
        ListDisplayMode.entries.find {
            it.value == prefs.getInt(LIST_SIZE_KEY, ListDisplayMode.REGULAR.value)
        } ?: ListDisplayMode.REGULAR
    )
    val listSize: StateFlow<ListDisplayMode> = _listSize

    private val _favoritesDisplayMode = MutableStateFlow(
        CircleDisplayMode.entries.find {
            it.value == prefs.getInt(FAVORITES_DISPLAY_MODE_KEY, CircleDisplayMode.GRID.value)
        } ?: CircleDisplayMode.GRID
    )
    val favoritesDisplayMode: StateFlow<CircleDisplayMode> = _favoritesDisplayMode

    private val _favoritesGroupByColor = MutableStateFlow(
        prefs.getBoolean(FAVORITES_GROUP_BY_COLOR_KEY, true)
    )
    val favoritesGroupByColor: StateFlow<Boolean> = _favoritesGroupByColor

    fun setGridSize(size: GridDisplayMode) {
        _gridSize.value = size
        prefs.edit { putInt(GRID_SIZE_KEY, size.value) }
    }

    fun setListSize(size: ListDisplayMode) {
        _listSize.value = size
        prefs.edit { putInt(LIST_SIZE_KEY, size.value) }
    }

    fun setFavoritesDisplayMode(mode: CircleDisplayMode) {
        _favoritesDisplayMode.value = mode
        prefs.edit { putInt(FAVORITES_DISPLAY_MODE_KEY, mode.value) }
    }

    fun setFavoritesGroupByColor(grouped: Boolean) {
        _favoritesGroupByColor.value = grouped
        prefs.edit { putBoolean(FAVORITES_GROUP_BY_COLOR_KEY, grouped) }
    }

    fun setShowSpaceName(show: Boolean) {
        _showSpaceName.value = show
        prefs.edit { putBoolean(SHOW_SPACE_NAME_KEY, show) }
    }

    fun setShowWebCuts(show: Boolean) {
        _showWebCuts.value = show
        prefs.edit { putBoolean(SHOW_WEB_CUTS_KEY, show) }
    }

    fun setShowDay(show: Boolean) {
        _showDay.value = show
        prefs.edit { putBoolean(SHOW_DAY_KEY, show) }
    }

    fun setDarkenMapInDarkMode(enabled: Boolean) {
        _darkenMapInDarkMode.value = enabled
        prefs.edit { putBoolean(DARKEN_MAP_IN_DARK_MODE_KEY, enabled) }
    }

    fun setUseHighResolutionMaps(enabled: Boolean) {
        _useHighResolutionMaps.value = enabled
        prefs.edit { putBoolean(USE_HIGH_RESOLUTION_MAPS_KEY, enabled) }
    }

    fun setMapZoomLevel(zoom: Float) {
        _mapZoomLevel.value = zoom
        prefs.edit { putFloat(MAP_ZOOM_LEVEL_KEY, zoom) }
    }

    fun setShowGenreOverlay(show: Boolean) {
        _showGenreOverlay.value = show
        prefs.edit { putBoolean(SHOW_GENRE_OVERLAY_KEY, show) }
    }

    fun setIsPrivacyMode(enabled: Boolean) {
        _isPrivacyMode.value = enabled
        prefs.edit { putBoolean(PRIVACY_MODE_KEY, enabled) }
    }

    fun setDisplayMode(mode: CircleDisplayMode) {
        _displayMode.value = mode
        prefs.edit { putInt(CIRCLE_DISPLAY_MODE_KEY, mode.value) }
    }

    fun setDate(date: ComiketDate?) {
        if (_date.value != date) {
            _date.value = date
            prefs.edit { putInt(SELECTED_DATE_KEY, date?.id ?: 0) }
            _genres.value = emptySet()
            prefs.edit { putStringSet(SELECTED_GENRES_KEY, emptySet()) }
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

    /**
     * Clears every persisted preference and resets in-memory state to
     * defaults, mirroring the iOS sign-out which wipes all UserDefaults.
     */
    fun wipeAll() {
        prefs.edit { clear() }
        _date.value = null
        _map.value = null
        _blocks.value = emptySet()
        _genres.value = emptySet()
        _showGenreOverlay.value = false
        _isPrivacyMode.value = false
        _showSpaceName.value = false
        _showDay.value = false
        _darkenMapInDarkMode.value = true
        _useHighResolutionMaps.value = true
        _mapZoomLevel.value = 1.0f
        _showWebCuts.value = false
        _displayMode.value = CircleDisplayMode.GRID
        _gridSize.value = GridDisplayMode.MEDIUM
        _listSize.value = ListDisplayMode.REGULAR
        _favoritesDisplayMode.value = CircleDisplayMode.GRID
        _favoritesGroupByColor.value = true
    }
}
