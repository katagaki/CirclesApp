package com.tsubuzaki.circlesgo.state

import android.content.Context
import android.util.Log
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.R
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import com.tsubuzaki.circlesgo.api.catalog.FavoritesAPI
import com.tsubuzaki.circlesgo.auth.Authenticator
import com.tsubuzaki.circlesgo.database.CatalogDatabase
import com.tsubuzaki.circlesgo.database.CatalogDatabaseDownloader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class DataManager(
    private val context: Context,
    private val authenticator: Authenticator,
    private val database: CatalogDatabase,
    private val events: Events,
    private val selections: UserSelections,
    private val favorites: FavoritesState,
    private val unifier: Unifier,
    private val oasis: Oasis,
    private val favoritesAPI: FavoritesAPI
) {

    companion object {
        private const val TAG = "DataManager"
        private const val PREFS_NAME = "circles_prefs"
        private const val DATABASE_INITIALIZED_KEY = "Database.Initialized"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    @Volatile
    private var isReloadingData = false

    private var isDatabaseInitialized: Boolean
        get() = prefs.getBoolean(DATABASE_INITIALIZED_KEY, false)
        set(value) = prefs.edit { putBoolean(DATABASE_INITIALIZED_KEY, value) }

    suspend fun reloadData(
        forceDownload: Boolean = false,
        shouldResetSelections: Boolean = false
    ) {
        if (isReloadingData) return
        isReloadingData = true

        try {
            database.reset()
            if (forceDownload) {
                isDatabaseInitialized = false
            }
            unifier.hide()

            // Step 1: Fetch events list from API
            val authToken = authenticator.token.value ?: OpenIDToken()
            events.prepare(authToken)

            // Step 2: Update active event based on online state
            events.updateActiveEvent(authenticator.onlineState.value)
            val activeEvent = events.activeEvent.value

            // Step 3: Download databases and load data
            if (activeEvent != null) {
                if (!database.isDownloaded(activeEvent)) {
                    // Database needs downloading - show progress dialog
                    oasis.open()
                    try {
                        loadDataFromDatabase(activeEvent, authToken)
                    } finally {
                        finishReload(shouldResetSelections = true)
                    }
                } else {
                    // Database exists, just load it
                    loadDataFromDatabase(activeEvent, authToken)
                    finishReload(shouldResetSelections = shouldResetSelections)
                }
            } else {
                finishReload(shouldResetSelections = shouldResetSelections)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to reload data", e)
            oasis.close()
            isReloadingData = false
        }
    }

    private fun finishReload(shouldResetSelections: Boolean = false) {
        oasis.close()

        if (shouldResetSelections) {
            selections.resetSelections()
        }

        // Set default selections from database
        if (shouldResetSelections || selections.date.value == null) {
            val defaultDate = selections.fetchDefaultDateSelection(database)
            if (defaultDate != null) {
                selections.setDate(defaultDate)
            }
        }
        if (shouldResetSelections || selections.map.value == null) {
            val defaultMap = selections.fetchDefaultMapSelection(database)
            if (defaultMap != null) {
                selections.setMap(defaultMap)
            }
        }

        // Show the UI
        if (!authenticator.isAuthenticating.value) {
            unifier.show()
        }
        isReloadingData = false
    }

    private suspend fun loadDataFromDatabase(
        activeEvent: com.tsubuzaki.circlesgo.api.catalog.WebCatalogEvent.Response.Event,
        authToken: OpenIDToken
    ) {
        val downloader = CatalogDatabaseDownloader(database)

        if (!database.isDownloaded(activeEvent)) {
            // Download text database
            oasis.setHeaderText(context.getString(R.string.downloading))
            oasis.setBodyText(context.getString(R.string.downloading_text_database))
            downloader.downloadTextDatabase(activeEvent, authToken) { progress ->
                oasis.setProgress(progress)
            }

            // Download image database
            oasis.setBodyText(context.getString(R.string.downloading_image_database))
            downloader.downloadImageDatabase(activeEvent, authToken) { progress ->
                oasis.setProgress(progress)
            }
        } else {
            database.prepare(activeEvent)
        }

        if (oasis.isShowing.value) {
            oasis.setBodyText(context.getString(R.string.loading_database))
        }

        // Reload selections from database
        selections.reloadData(database)

        if (oasis.isShowing.value) {
            oasis.setHeaderText(context.getString(R.string.loading))
        }

        // Load images
        if (!isDatabaseInitialized) {
            isDatabaseInitialized = true
        }

        withContext(Dispatchers.IO) {
            database.loadCommonImages()
            database.loadCircleImages()
        }

        // Load favorites in background
        loadFavorites(authToken)
    }

    private suspend fun loadFavorites(authToken: OpenIDToken) {
        try {
            val (items, wcIDMappedItems) = withContext(Dispatchers.IO) {
                favoritesAPI.all(authToken)
            }
            favorites.setItems(items)
            favorites.setWcIDMappedItems(wcIDMappedItems)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load favorites", e)
        }
    }
}
