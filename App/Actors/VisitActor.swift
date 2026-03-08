//
//  VisitActor.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/23.
//

import Foundation
import SwiftData

@ModelActor
actor VisitActor {

    func toggleVisit(circleID: Int, eventNumber: Int) {
        let fetchDescriptor = FetchDescriptor<CirclesVisitEntry>(
            predicate: #Predicate {
                $0.circleID == circleID && $0.eventNumber == eventNumber
            }
        )
        if let existingVisits = try? modelContext.fetch(fetchDescriptor) {
            if existingVisits.isEmpty {
                modelContext.insert(
                    CirclesVisitEntry(eventNumber: eventNumber,
                                      circleID: circleID,
                                      visitDate: .now)
                )
            } else {
                for visit in existingVisits {
                    modelContext.delete(visit)
                }
            }
        }
        try? modelContext.save()
    }
}
