package com.tsubuzaki.circlesgo.state

import android.content.Context
import androidx.core.content.edit
import com.tsubuzaki.circlesgo.api.OnlineState
import com.tsubuzaki.circlesgo.api.auth.OpenIDToken
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogAPI
import com.tsubuzaki.circlesgo.api.catalog.WebCatalogEvent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.json.JSONObject

class Events(private val context: Context) {

    companion object {
        private const val PREFS_NAME = "circles_prefs"
        private const val ACTIVE_EVENT_NUMBER_KEY = "Events.Active.Number"
        private const val ACTIVE_EVENT_IS_LATEST_KEY = "Events.Active.IsLatest"
        private const val PARTICIPATION_KEY = "My.Participation"
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var eventData: WebCatalogEvent.Response? = null
        private set
    var latestEvent: WebCatalogEvent.Response.Event? = null
        private set

    private val _activeEvent = MutableStateFlow<WebCatalogEvent.Response.Event?>(null)
    val activeEvent: StateFlow<WebCatalogEvent.Response.Event?> = _activeEvent

    var activeEventNumber: Int = prefs.getInt(ACTIVE_EVENT_NUMBER_KEY, -1)
        private set

    var isActiveEventLatest: Boolean
        get() = prefs.getBoolean(ACTIVE_EVENT_IS_LATEST_KEY, false)
        set(value) {
            prefs.edit { putBoolean(ACTIVE_EVENT_IS_LATEST_KEY, value) }
        }

    fun setActiveEvent(number: Int) {
        if (activeEventNumber != number) {
            activeEventNumber = number
            prefs.edit { putInt(ACTIVE_EVENT_NUMBER_KEY, activeEventNumber) }

            // update _activeEvent immediately if data is available
            val eventInList = eventData?.list?.firstOrNull { it.number == activeEventNumber }
            if (eventInList != null) {
                _activeEvent.value = WebCatalogEvent.Response.Event(
                    id = eventInList.id,
                    number = activeEventNumber
                )
            }
        }
    }

    suspend fun prepare(authToken: OpenIDToken) {
        if (eventData != null && latestEvent != null) {
            if (activeEventNumber == -1) {
                activeEventNumber = latestEvent!!.number
                prefs.edit { putInt(ACTIVE_EVENT_NUMBER_KEY, activeEventNumber) }
                isActiveEventLatest = true
            }
            isActiveEventLatest = activeEventNumber == eventData!!.latestEventNumber

            val eventInList = eventData!!.list.firstOrNull { it.number == activeEventNumber }
            if (eventInList != null) {
                _activeEvent.value = WebCatalogEvent.Response.Event(
                    id = eventInList.id,
                    number = activeEventNumber
                )
            }
        } else {
            eventData = WebCatalogAPI.events(authToken, context)
            latestEvent = eventData?.list?.firstOrNull { it.id == eventData?.latestEventID }
            prepare(authToken)
        }
    }

    fun updateActiveEvent(onlineState: OnlineState) {
        when (onlineState) {
            OnlineState.ONLINE -> {
                val eventInList = eventData?.list?.firstOrNull { it.number == activeEventNumber }
                if (eventInList != null) {
                    _activeEvent.value = WebCatalogEvent.Response.Event(
                        id = eventInList.id,
                        number = activeEventNumber
                    )
                }
            }

            OnlineState.OFFLINE -> {
                _activeEvent.value = WebCatalogEvent.Response.Event(
                    id = activeEventNumber,
                    number = activeEventNumber
                )
            }

            OnlineState.UNDETERMINED -> {}
        }
    }

    fun participationInfo(day: Int): String? {
        val participationJson = prefs.getString(PARTICIPATION_KEY, null) ?: return null
        return try {
            val json = JSONObject(participationJson)
            val eventObj = json.optJSONObject(activeEventNumber.toString()) ?: return null
            eventObj.optString(day.toString(), null)
        } catch (e: Exception) {
            null
        }
    }

    fun setParticipation(day: Int, value: String) {
        val participationJson = prefs.getString(PARTICIPATION_KEY, null)
        val json = if (participationJson != null) {
            try {
                JSONObject(participationJson)
            } catch (e: Exception) {
                JSONObject()
            }
        } else {
            JSONObject()
        }

        val eventKey = activeEventNumber.toString()
        val eventObj = json.optJSONObject(eventKey) ?: JSONObject()
        eventObj.put(day.toString(), value)
        json.put(eventKey, eventObj)

        prefs.edit { putString(PARTICIPATION_KEY, json.toString()) }
    }
}
