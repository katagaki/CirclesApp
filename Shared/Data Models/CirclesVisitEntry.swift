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
    var eventID: Int
    var circleID: Int
    var visitDate: Date?

    init(eventID: Int, circleID: Int, visitDate: Date? = nil) {
        self.eventID = eventID
        self.circleID = circleID
        self.visitDate = visitDate
    }
}
