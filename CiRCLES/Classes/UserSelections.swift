//
//  UserSelections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import Foundation
import Observation

let selectedGenresKey = "Circles.SelectedGenreIDs"
let selectedMapKey = "Circles.SelectedMapID"
let selectedBlocksKey = "Circles.SelectedBlockIDs"
let selectedDateKey = "Circles.SelectedDateID"

@MainActor
@Observable
class UserSelections {

    @ObservationIgnored let defaults: UserDefaults

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
    }

    @MainActor
    func reloadData(database: Database) {
        let dateID = defaults.integer(forKey: selectedDateKey)
        let mapID = defaults.integer(forKey: selectedMapKey)
        let blockIDs = defaults.array(forKey: selectedBlocksKey) as? [Int] ?? []
        let genreIDs = defaults.array(forKey: selectedGenresKey) as? [Int] ?? []
        database.connect()
        _date = database.allDates().first(where: { $0.id == dateID })
        _map = database.allMaps().first(where: { $0.id == mapID })
        _blocks = Set(database.allBlocks().filter({ blockIDs.contains($0.id) }))
        _genres = Set(database.allGenres().filter({ genreIDs.contains($0.id) }))
    }

    @MainActor
    func fetchDefaultDateSelection(database: Database) -> ComiketDate? {
        database.connect()
        return database.allDates().first
    }

    @MainActor
    func fetchDefaultMapSelection(database: Database) -> ComiketMap? {
        database.connect()
        return database.allMaps().first
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

}
