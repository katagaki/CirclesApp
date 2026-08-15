//
//  CircleDetailVisitButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/15.
//

import SwiftData
import SwiftUI
import AXiS

struct CircleDetailVisitButton: View {

    @Environment(\.modelContext) var modelContext
    @Environment(Events.self) var planner

    @Query var visits: [CirclesVisitEntry]

    var circle: ComiketCircle

    var currentVisit: CirclesVisitEntry? {
        visits.first(where: { $0.circleID == circle.id && $0.eventNumber == planner.activeEventNumber })
    }

    var body: some View {
        if currentVisit != nil {
            Button("Shared.MarkNotVisited", systemImage: "eye.slash") {
                toggleVisited()
            }
        } else {
            Button("Shared.MarkVisited", systemImage: "eye") {
                toggleVisited()
            }
        }
    }

    func toggleVisited() {
        if let currentVisit {
            modelContext.delete(currentVisit)
        } else {
            modelContext.insert(
                CirclesVisitEntry(
                    eventNumber: planner.activeEventNumber,
                    circleID: circle.id
                )
            )
        }
    }
}
