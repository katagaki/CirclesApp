package com.tsubuzaki.circlesgo.state

import com.tsubuzaki.circlesgo.data.local.VisitEntryCache
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Observable wrapper around [VisitEntryCache] so views (circle detail,
 * map visited layer) can react to visit changes.
 */
class VisitsState(private val cache: VisitEntryCache) {

    private val _visits = MutableStateFlow<List<VisitEntryCache.VisitEntry>>(emptyList())
    val visits: StateFlow<List<VisitEntryCache.VisitEntry>> = _visits

    init {
        reload()
    }

    fun isVisited(circleID: Int, eventNumber: Int): Boolean {
        return _visits.value.any { it.circleID == circleID && it.eventNumber == eventNumber }
    }

    fun visitedCircleIDs(eventNumber: Int): List<Int> {
        return _visits.value.filter { it.eventNumber == eventNumber }.map { it.circleID }
    }

    fun toggleVisit(circleID: Int, eventNumber: Int) {
        if (isVisited(circleID, eventNumber)) {
            cache.delete(eventNumber, circleID)
        } else {
            cache.insert(
                VisitEntryCache.VisitEntry(
                    eventNumber = eventNumber,
                    circleID = circleID,
                    visitDate = System.currentTimeMillis()
                )
            )
        }
        reload()
    }

    private fun reload() {
        _visits.value = cache.all()
    }
}
