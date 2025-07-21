//
//  UserSelections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import Foundation
import Observation
import SwiftData

let selectedGenreKey = "Circles.SelectedGenreID"
let selectedMapKey = "Circles.SelectedMapID"
let selectedBlockKey = "Circles.SelectedBlockID"
let selectedDateKey = "Circles.SelectedDateID"

@Observable
class UserSelections: Equatable {
    @ObservationIgnored let defaults: UserDefaults
    @ObservationIgnored let modelContext: ModelContext

    // swiftlint:disable identifier_name
    @ObservationIgnored var _date: ComiketDate?
    var date: ComiketDate? {
        get { return _date }
        set(value) {
            defaults.set(value?.id, forKey: selectedDateKey)
            _date = value
        }
    }
    @ObservationIgnored var _map: ComiketMap?
    var map: ComiketMap? {
        get { return _map }
        set(value) {
            defaults.set(value?.id, forKey: selectedMapKey)
            defaults.set(nil, forKey: selectedBlockKey)
            _map = value
            _block = nil
        }
    }
    @ObservationIgnored var _block: ComiketBlock?
    var block: ComiketBlock? {
        get { return _block }
        set(value) {
            defaults.set(value?.id, forKey: selectedBlockKey)
            _block = value
        }
    }
    @ObservationIgnored var _genre: ComiketGenre?
    var genre: ComiketGenre? {
        get { return _genre }
        set(value) {
            defaults.set(value?.id, forKey: selectedGenreKey)
            _genre = value
        }
    }
    // swiftlint:enable identifier_name

    @MainActor
    init() {
        defaults = UserDefaults.standard
        modelContext = sharedModelContainer.mainContext
        reloadData()
    }

    func reloadData() {
        let dateID = defaults.integer(forKey: selectedGenreKey)
        let mapID = defaults.integer(forKey: selectedMapKey)
        let blockID = defaults.integer(forKey: selectedGenreKey)
        let genreID = defaults.integer(forKey: selectedGenreKey)
        _date = fetchDateSelection(with: dateID)
        _map = fetchMapSelection(with: mapID)
        _block = fetchBlockSelection(with: blockID)
        _genre = fetchGenreSelection(with: genreID)
    }

    func fetchDateSelection(with id: Int) -> ComiketDate? {
        let fetchDescriptor = FetchDescriptor<ComiketDate>(
            predicate: #Predicate<ComiketDate> { $0.id == id }
        )
        return try? modelContext.fetch(fetchDescriptor).first
    }

    func fetchMapSelection(with id: Int) -> ComiketMap? {
        let fetchDescriptor = FetchDescriptor<ComiketMap>(
            predicate: #Predicate<ComiketMap> { $0.id == id }
        )
        return try? modelContext.fetch(fetchDescriptor).first
    }

    func fetchBlockSelection(with id: Int) -> ComiketBlock? {
        let fetchDescriptor = FetchDescriptor<ComiketBlock>(
            predicate: #Predicate<ComiketBlock> { $0.id == id }
        )
        return try? modelContext.fetch(fetchDescriptor).first
    }

    func fetchGenreSelection(with id: Int) -> ComiketGenre? {
        let fetchDescriptor = FetchDescriptor<ComiketGenre>(
            predicate: #Predicate<ComiketGenre> { $0.id == id }
        )
        return try? modelContext.fetch(fetchDescriptor).first
    }

    var idMap: [Int?] { [genre?.id, map?.id, block?.id, date?.id] }

    static func == (lhs: UserSelections, rhs: UserSelections) -> Bool {
        return lhs.idMap == rhs.idMap
    }
}
