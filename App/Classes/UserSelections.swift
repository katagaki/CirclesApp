//
//  UserSelections.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/07/21.
//

import Foundation
import Observation
import AXiS

let selectedGenresKey = "Circles.SelectedGenreIDs"
let selectedMapKey = "Circles.SelectedMapID"
let selectedBlocksKey = "Circles.SelectedBlockIDs"
let selectedDateKey = "Circles.SelectedDateID"

@MainActor
@Observable
class UserSelections {

    @ObservationIgnored let defaults: UserDefaults

    private var dateValue: ComiketDate?
    var date: ComiketDate? {
        get { return dateValue }
        set(value) {
            if dateValue != value {
                dateValue = value
                defaults.set(value?.id, forKey: selectedDateKey)
                genresValue = []
                defaults.set([], forKey: selectedGenresKey)
                blocksValue = []
                defaults.set([], forKey: selectedBlocksKey)
            }
        }
    }
    private var mapValue: ComiketMap?
    var map: ComiketMap? {
        get { return mapValue }
        set(value) {
            if mapValue != value {
                mapValue = value
                defaults.set(value?.id, forKey: selectedMapKey)
                genresValue = []
                defaults.set([], forKey: selectedGenresKey)
                blocksValue = []
                defaults.set([], forKey: selectedBlocksKey)
            }
        }
    }
    private var blocksValue: Set<ComiketBlock> = []
    var blocks: Set<ComiketBlock> {
        get { return blocksValue }
        set(value) {
            blocksValue = value
            defaults.set(value.map({ $0.id }), forKey: selectedBlocksKey)
        }
    }
    private var genresValue: Set<ComiketGenre> = []
    var genres: Set<ComiketGenre> {
        get { return genresValue }
        set(value) {
            genresValue = value
            defaults.set(value.map({ $0.id }), forKey: selectedGenresKey)
        }
    }

    @MainActor
    init() {
        defaults = UserDefaults.standard
    }

    @MainActor
    func reloadData(database: Database) {
        let dateID = defaults.object(forKey: selectedDateKey) as? Int ?? 0
        let mapID = defaults.object(forKey: selectedMapKey) as? Int ?? 0
        dateValue = database.dates().first(where: { $0.id == dateID })
        mapValue = database.maps().first(where: { $0.id == mapID })

        let blockIDs = defaults.array(forKey: selectedBlocksKey) as? [Int] ?? []
        let genreIDs = defaults.array(forKey: selectedGenresKey) as? [Int] ?? []
        blocksValue = Set(database.blocks().filter({ blockIDs.contains($0.id) }))
        genresValue = Set(database.genres().filter({ genreIDs.contains($0.id) }))
    }

    @MainActor
    func fetchDefaultDateSelection(database: Database) -> ComiketDate? {
        return database.dates().first
    }

    @MainActor
    func fetchDefaultMapSelection(database: Database) -> ComiketMap? {
        return database.maps().first
    }

    var fullMapID: String {
        return "M\(mapValue?.id ?? -1),D\(dateValue?.id ?? -1)"
    }

    var catalogSelectionID: String {
        let genreIDs = genresValue.map({ String($0.id) }).sorted().joined(separator: "-")
        let blockIDs = blocksValue.map({ String($0.id) }).sorted().joined(separator: "-")
        return "M\(mapValue?.id ?? -1),D\(dateValue?.id ?? -1),G[\(genreIDs)],B[\(blockIDs)]"
    }

    func resetSelections() {
        defaults.set(0, forKey: selectedDateKey)
        defaults.set(0, forKey: selectedMapKey)

        genresValue = []
        defaults.set([], forKey: selectedGenresKey)
        blocksValue = []
        defaults.set([], forKey: selectedBlocksKey)
    }

}
