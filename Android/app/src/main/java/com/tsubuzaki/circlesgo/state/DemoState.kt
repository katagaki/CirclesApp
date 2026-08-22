package com.tsubuzaki.circlesgo.state

import android.content.Context
import androidx.core.content.edit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class DemoState(context: Context) {

    companion object {
        const val DEFAULT_DATASET = 999
        val DATASET_EVENT_NUMBERS = listOf(999, 998)
        val PLACEHOLDER_EVENT_NUMBERS = (990..999).toList()

        private const val PREFS_NAME = "circles_prefs"
        private const val SELECTED_DATASET_KEY = "Demo.SelectedDataset"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _isActive = MutableStateFlow(false)
    val isActive: StateFlow<Boolean> = _isActive

    var selectedDataset: Int
        get() {
            val stored = prefs.getInt(SELECTED_DATASET_KEY, DEFAULT_DATASET)
            return if (stored in DATASET_EVENT_NUMBERS) stored else DEFAULT_DATASET
        }
        set(value) {
            if (value in DATASET_EVENT_NUMBERS) {
                prefs.edit { putInt(SELECTED_DATASET_KEY, value) }
            }
        }

    fun activate() {
        _isActive.value = true
    }

    fun deactivate() {
        _isActive.value = false
    }

    /** Leaves demo mode and forgets the dataset that was being previewed. */
    fun reset() {
        _isActive.value = false
        prefs.edit { remove(SELECTED_DATASET_KEY) }
    }

    fun isDataset(eventNumber: Int): Boolean = eventNumber in DATASET_EVENT_NUMBERS
}
