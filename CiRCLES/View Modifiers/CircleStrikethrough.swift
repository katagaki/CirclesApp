//
//  CircleStrikethrough.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/17.
//

import SwiftData
import SwiftUI

struct CircleStrikethrough: ViewModifier {

    @Environment(Planner.self) var planner

    @Query var visits: [CirclesVisitEntry]

    init(circle: ComiketCircle) {
        let circleID = circle.id
        self._visits = Query(
            filter: #Predicate {
                $0.circleID == circleID
            }
        )
    }

    func body(content: Content) -> some View {
        if !visits.filter({$0.eventNumber == planner.activeEventNumber}).isEmpty {
            content
                .strikethrough()
                .opacity(0.6)
        } else {
            content
        }
    }
}

extension View {
    func strikethrough(circle: ComiketCircle) -> some View {
        self.modifier(CircleStrikethrough(circle: circle))
    }
}
