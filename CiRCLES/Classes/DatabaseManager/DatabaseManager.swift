//
//  DatabaseManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation
import SQLite
import UIKit

@Observable
@MainActor
class DatabaseManager {

    @ObservationIgnored let documentsDirectoryURL: URL? = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first

    var textDatabaseURL: URL?
    var imageDatabaseURL: URL?

    var textDatabase: Connection?
    var imageDatabase: Connection?

    var events: [ComiketEvent] = []
    var eventDates: [ComiketDate] = []
    var eventMaps: [ComiketMap] = []
    var eventAreas: [ComiketArea] = []
    var eventBlocks: [ComiketBlock] = []
    var eventGenres: [ComiketGenre] = []
    var eventLayouts: [ComiketLayout] = []
    var eventCircles: [ComiketCircle] = []
    var eventCircleExtendedInformation: [ComiketCircleExtendedInformation] = []

    var commonImages: [String: Data] = [:]
    var circleImages: [Int: Data] = [:]

    func deleteDatabases() {
        if let documentsDirectoryURL {
            try? FileManager.default.removeItem(at: documentsDirectoryURL)
            self.textDatabaseURL = nil
            self.imageDatabaseURL = nil
            self.textDatabase = nil
            self.imageDatabase = nil
            self.events.removeAll()
            self.eventDates.removeAll()
            self.eventMaps.removeAll()
            self.eventAreas.removeAll()
        }
    }

}
