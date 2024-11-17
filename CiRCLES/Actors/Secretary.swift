//
//  Secretary.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/17.
//

import Foundation
import SwiftData

@ModelActor
actor Secretary {

    func hasVisitEntry(in eventNumber: Int, for circleID: Int) -> Bool {
        let fetchDescriptor = FetchDescriptor<CirclesVisitEntry>(
            predicate: #Predicate<CirclesVisitEntry> {
                $0.eventNumber == eventNumber &&
                $0.circleID == circleID
            }
        )
        if let visits = try? modelContext.fetch(fetchDescriptor),
           visits.first != nil {
            return true
        } else {
            return false
        }
    }

    func markVisited(in eventNumber: Int, for circleID: Int) {
        modelContext.insert(
            CirclesVisitEntry(
                eventNumber: eventNumber,
                circleID: circleID
            )
        )
        try? modelContext.save()
    }

    func markNotVisited(in eventNumber: Int, for circleID: Int) {
        let fetchDescriptor = FetchDescriptor<CirclesVisitEntry>(
            predicate: #Predicate<CirclesVisitEntry> {
                $0.eventNumber == eventNumber &&
                $0.circleID == circleID
            }
        )
        if let visits = try? modelContext.fetch(fetchDescriptor) {
            for visit in visits {
                modelContext.delete(visit)
            }
        }
        try? modelContext.save()
    }
}
