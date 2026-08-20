//
//  BackupActor.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/20.
//

import Foundation
import SwiftData

struct BackupVisit: Codable, Sendable {
    let eventNumber: Int
    let circleID: Int
    let visitDate: Date?
}

@ModelActor
actor BackupActor {

    func visitsData() -> Data {
        let visits = (try? modelContext.fetch(FetchDescriptor<CirclesVisitEntry>())) ?? []
        let encodable = visits.map {
            BackupVisit(eventNumber: $0.eventNumber, circleID: $0.circleID, visitDate: $0.visitDate)
        }
        return (try? JSONEncoder().encode(encodable)) ?? Data("[]".utf8)
    }

    /// Merges the backed up visits in, keeping any visit that already exists locally.
    func restoreVisits(from data: Data) {
        guard let visits = try? JSONDecoder().decode([BackupVisit].self, from: data) else { return }
        let existing = (try? modelContext.fetch(FetchDescriptor<CirclesVisitEntry>())) ?? []
        var existingKeys = Set(existing.map { "\($0.eventNumber)-\($0.circleID)" })
        for visit in visits {
            let key = "\(visit.eventNumber)-\(visit.circleID)"
            guard !existingKeys.contains(key) else { continue }
            existingKeys.insert(key)
            modelContext.insert(
                CirclesVisitEntry(
                    eventNumber: visit.eventNumber, circleID: visit.circleID, visitDate: visit.visitDate
                )
            )
        }
        try? modelContext.save()
    }
}
