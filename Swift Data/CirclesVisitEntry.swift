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
