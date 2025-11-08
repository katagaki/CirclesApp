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

    private var _date: ComiketDate?
    var date: ComiketDate? {
        get { return _date }
        set(value) {
            _date = value
            defaults.set(value?.id, forKey: selectedDateKey)
        }
    }
    private var _map: ComiketMap?
    var map: ComiketMap? {
        get { return _map }
        set(value) {
            _map = value
            defaults.set(value?.id, forKey: selectedMapKey)
            _block = nil
            defaults.set(nil, forKey: selectedBlockKey)
        }
    }
    private var _block: ComiketBlock?
    var block: ComiketBlock? {
        get { return _block }
        set(value) {
            _block = value
            defaults.set(value?.id, forKey: selectedBlockKey)
        }
    }
    private var _genre: ComiketGenre?
    var genre: ComiketGenre? {
        get { return _genre }
        set(value) {
            _genre = value
            defaults.set(value?.id, forKey: selectedGenreKey)
        }
    }

    @MainActor
    init() {
        defaults = UserDefaults.standard
        modelContext = sharedModelContainer.mainContext
        reloadData()
    }

    @MainActor
    func reloadData() {
        let dateID = defaults.integer(forKey: selectedDateKey)
        let mapID = defaults.integer(forKey: selectedMapKey)
        let blockID = defaults.integer(forKey: selectedBlockKey)
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

    func fetchDefaultDateSelection() -> ComiketDate? {
        let fetchDescriptor = FetchDescriptor<ComiketDate>(
            sortBy: [SortDescriptor(\.id)]
        )
        return try? modelContext.fetch(fetchDescriptor).first
    }

    func fetchMapSelection(with id: Int) -> ComiketMap? {
        let fetchDescriptor = FetchDescriptor<ComiketMap>(
            predicate: #Predicate<ComiketMap> { $0.id == id }
        )
        return try? modelContext.fetch(fetchDescriptor).first
    }

    func fetchDefaultMapSelection() -> ComiketMap? {
        let fetchDescriptor = FetchDescriptor<ComiketMap>(
            sortBy: [SortDescriptor(\.id)]
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

    var fullMapId: String {
        return "M\(_map?.id ?? 0),D\(_date?.id ?? 0)"
    }

    var catalogSelectionId: String {
        return "G\(_genre?.id ?? 0),B\(_block?.id ?? 0)"
    }

    static func == (lhs: UserSelections, rhs: UserSelections) -> Bool {
        return lhs.fullMapId == rhs.fullMapId &&
        lhs.catalogSelectionId == rhs.catalogSelectionId
    }
}
