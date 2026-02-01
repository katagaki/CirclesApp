//
//  UserSelections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import Foundation
import Observation
import SwiftData

let selectedGenresKey = "Circles.SelectedGenreIDs"
let selectedMapKey = "Circles.SelectedMapID"
let selectedBlocksKey = "Circles.SelectedBlockIDs"
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
            _blocks = []
            defaults.set([], forKey: selectedBlocksKey)
        }
    }
    private var _blocks: Set<ComiketBlock> = []
    var blocks: Set<ComiketBlock> {
        get { return _blocks }
        set(value) {
            _blocks = value
            defaults.set(value.map({ $0.id }), forKey: selectedBlocksKey)
        }
    }
    private var _genres: Set<ComiketGenre> = []
    var genres: Set<ComiketGenre> {
        get { return _genres }
        set(value) {
            _genres = value
            defaults.set(value.map({ $0.id }), forKey: selectedGenresKey)
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
        let blockIDs = defaults.array(forKey: selectedBlocksKey) as? [Int] ?? []
        let genreIDs = defaults.array(forKey: selectedGenresKey) as? [Int] ?? []
        _date = fetchDateSelection(with: dateID)
        _map = fetchMapSelection(with: mapID)
        _blocks = fetchBlockSelections(with: blockIDs)
        _genres = fetchGenreSelections(with: genreIDs)
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

    func fetchBlockSelections(with ids: [Int]) -> Set<ComiketBlock> {
        let fetchDescriptor = FetchDescriptor<ComiketBlock>(
            predicate: #Predicate<ComiketBlock> { ids.contains($0.id) }
        )
        return Set((try? modelContext.fetch(fetchDescriptor)) ?? [])
    }

    func fetchGenreSelections(with ids: [Int]) -> Set<ComiketGenre> {
        let fetchDescriptor = FetchDescriptor<ComiketGenre>(
            predicate: #Predicate<ComiketGenre> { ids.contains($0.id) }
        )
        return Set((try? modelContext.fetch(fetchDescriptor)) ?? [])
    }

    var fullMapID: String {
        return "M\(_map?.id ?? -1),D\(_date?.id ?? -1)"
    }

    var catalogSelectionID: String {
        let genreIDs = _genres.map({ String($0.id) }).sorted().joined(separator: "-")
        let blockIDs = _blocks.map({ String($0.id) }).sorted().joined(separator: "-")
        return "M\(_map?.id ?? -1),D\(_date?.id ?? -1),G[\(genreIDs)],B[\(blockIDs)]"
    }

    func resetSelections() {
        _genres = []
        defaults.set([], forKey: selectedGenresKey)
        _map = nil
        defaults.set(nil, forKey: selectedMapKey)
        _blocks = []
        defaults.set([], forKey: selectedBlocksKey)
        _date = nil
        defaults.set(nil, forKey: selectedDateKey)
    }

    static func == (lhs: UserSelections, rhs: UserSelections) -> Bool {
        return lhs.fullMapID == rhs.fullMapID &&
        lhs.catalogSelectionID == rhs.catalogSelectionID
    }
}
