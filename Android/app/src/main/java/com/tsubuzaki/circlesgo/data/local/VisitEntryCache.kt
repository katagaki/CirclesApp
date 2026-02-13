package com.tsubuzaki.circlesgo.data.local

import android.content.Context
import androidx.core.content.edit
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

class VisitEntryCache(context: Context) {

    companion object {
        private const val PREFS_NAME = "circles_visit_entries_cache"
        private const val ENTRIES_KEY = "cached_entries"
        private val json = Json { ignoreUnknownKeys = true }
    }

    @Serializable
    data class VisitEntry(
        val eventNumber: Int,
        val circleID: Int,
        val visitDate: Long? = null
    )

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getVisits(eventNumber: Int, circleID: Int): List<VisitEntry> {
        return loadAll().filter { it.eventNumber == eventNumber && it.circleID == circleID }
    }

    fun insert(entry: VisitEntry) {
        val all = loadAll().toMutableList()
        all.add(entry)
        saveAll(all)
    }

    fun delete(eventNumber: Int, circleID: Int) {
        val all = loadAll().toMutableList()
        all.removeAll { it.eventNumber == eventNumber && it.circleID == circleID }
        saveAll(all)
    }

    private fun loadAll(): List<VisitEntry> {
        val encoded = prefs.getString(ENTRIES_KEY, null) ?: return emptyList()
        return try {
            json.decodeFromString(encoded)
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun saveAll(entries: List<VisitEntry>) {
        prefs.edit { putString(ENTRIES_KEY, json.encodeToString(entries)) }
    }
}
