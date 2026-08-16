package com.tsubuzaki.circlesgo.data.local

import android.content.Context
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.UUID

/**
 * Stores planned purchases ("buys") per event, mirroring the iOS BuysDatabase.
 * Entries are keyed by circle ID; each entry holds an ordered list of items.
 */
class BuysCache(context: Context) {

    companion object {
        private const val PREFS_NAME = "circles_buys_cache"
        private val json = Json { ignoreUnknownKeys = true }

        const val STATUS_PENDING = 0
        const val STATUS_BOUGHT = 1
        const val STATUS_CANCELLED = 2

        fun nextStatus(status: Int): Int {
            return when (status) {
                STATUS_PENDING -> STATUS_BOUGHT
                STATUS_BOUGHT -> STATUS_CANCELLED
                else -> STATUS_PENDING
            }
        }
    }

    @Serializable
    data class BuyItem(
        val id: String = UUID.randomUUID().toString(),
        val name: String = "",
        val cost: Int = 0,
        val status: Int = STATUS_PENDING,
        val sortOrder: Int = 0
    )

    @Serializable
    data class BuyEntry(
        val circleID: Int,
        val items: List<BuyItem> = emptyList()
    )

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // Bumped after every mutation so views can observe changes
    private val _version = MutableStateFlow(0)
    val version: StateFlow<Int> = _version

    fun entries(eventNumber: Int): List<BuyEntry> {
        return loadAll(eventNumber)
    }

    fun entry(circleID: Int, eventNumber: Int): BuyEntry? {
        return loadAll(eventNumber).firstOrNull { it.circleID == circleID }
    }

    fun addItem(circleID: Int, eventNumber: Int, item: BuyItem = BuyItem()): BuyItem {
        val all = loadAll(eventNumber).toMutableList()
        val index = all.indexOfFirst { it.circleID == circleID }
        val newItem: BuyItem
        if (index >= 0) {
            val entry = all[index]
            val maxOrder = entry.items.maxOfOrNull { it.sortOrder } ?: -1
            newItem = item.copy(sortOrder = maxOrder + 1)
            all[index] = entry.copy(items = entry.items + newItem)
        } else {
            newItem = item.copy(sortOrder = 0)
            all.add(BuyEntry(circleID = circleID, items = listOf(newItem)))
        }
        saveAll(eventNumber, all)
        return newItem
    }

    fun updateItem(circleID: Int, eventNumber: Int, item: BuyItem) {
        val all = loadAll(eventNumber).toMutableList()
        val index = all.indexOfFirst { it.circleID == circleID }
        if (index < 0) return
        val entry = all[index]
        all[index] = entry.copy(
            items = entry.items.map { if (it.id == item.id) item else it }
        )
        saveAll(eventNumber, all)
    }

    fun deleteItem(circleID: Int, eventNumber: Int, itemID: String) {
        val all = loadAll(eventNumber).toMutableList()
        val index = all.indexOfFirst { it.circleID == circleID }
        if (index < 0) return
        val entry = all[index]
        val remaining = entry.items.filter { it.id != itemID }
        if (remaining.isEmpty()) {
            all.removeAt(index)
        } else {
            all[index] = entry.copy(items = remaining)
        }
        saveAll(eventNumber, all)
    }

    private fun key(eventNumber: Int) = "buys_$eventNumber"

    private fun loadAll(eventNumber: Int): List<BuyEntry> {
        val encoded = prefs.getString(key(eventNumber), null) ?: return emptyList()
        return try {
            json.decodeFromString(encoded)
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun saveAll(eventNumber: Int, entries: List<BuyEntry>) {
        prefs.edit { putString(key(eventNumber), json.encodeToString(entries)) }
        _version.value += 1
    }
}
