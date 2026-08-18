//
//  CircleDetailVisitToggle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/18.
//

import SwiftData
import SwiftUI
import AXiS

struct CircleDetailVisitToggle: View {

    @Environment(\.modelContext) var modelContext
    @Environment(Events.self) var planner

    @Query var visits: [CirclesVisitEntry]

    var circle: ComiketCircle
    var size: CGFloat

    var currentVisit: CirclesVisitEntry? {
        visits.first(where: { $0.circleID == circle.id && $0.eventNumber == planner.activeEventNumber })
    }

    var body: some View {
        Color.clear
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .onTapGesture {
                toggleVisited()
            }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(currentVisit != nil ? "Shared.MarkNotVisited" : "Shared.MarkVisited")
            .sensoryFeedback(.impact(weight: .light), trigger: currentVisit != nil)
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
