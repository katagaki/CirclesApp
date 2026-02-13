package com.tsubuzaki.circlesgo.data.repository

import com.tsubuzaki.circlesgo.data.local.VisitEntryCache

class VisitRepository(private val visitEntryCache: VisitEntryCache) {

    fun toggleVisit(circleID: Int, eventNumber: Int) {
        val existingVisits = visitEntryCache.getVisits(eventNumber, circleID)
        if (existingVisits.isEmpty()) {
            visitEntryCache.insert(
                VisitEntryCache.VisitEntry(
                    eventNumber = eventNumber,
                    circleID = circleID,
                    visitDate = System.currentTimeMillis()
                )
            )
        } else {
            visitEntryCache.delete(eventNumber, circleID)
        }
    }
}
