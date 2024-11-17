//
//  CirclesVisitEntry.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/16.
//

import Foundation
import SwiftData

@Model
final class CirclesVisitEntry {
    var eventNumber: Int
    var circleID: Int
    var visitDate: Date?

    init(eventNumber: Int, circleID: Int, visitDate: Date? = nil) {
        self.eventNumber = eventNumber
        self.circleID = circleID
        self.visitDate = visitDate
    }
}
