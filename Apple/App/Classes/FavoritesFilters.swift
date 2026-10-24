import Combine
import Foundation
import SwiftUI

let filteredColorsKey = "Favorites.FilteredColors"
let filteredHallsKey = "Favorites.FilteredHalls"

@MainActor
final class FavoritesFilters: ObservableObject {

    @Published var colors: Set<Int> = [] {
        didSet {
            UserDefaults.standard.set(Array(colors), forKey: filteredColorsKey)
        }
    }
    @Published var halls: Set<Int> = [] {
        didSet {
            UserDefaults.standard.set(Array(halls), forKey: filteredHallsKey)
        }
    }
    @Published var hasUncoloredFavorites: Bool = false

    var mapIDsByBlockID: [Int: Int] = [:]

    init() {
        let defaults = UserDefaults.standard
        self.colors = Set(defaults.array(forKey: filteredColorsKey) as? [Int] ?? [])
        self.halls = Set(defaults.array(forKey: filteredHallsKey) as? [Int] ?? [])
    }
}

struct FavoritesFiltersKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = FavoritesFilters()
}

extension EnvironmentValues {
    var favoritesFilters: FavoritesFilters {
        get { self[FavoritesFiltersKey.self] }
        set { self[FavoritesFiltersKey.self] = newValue }
    }
}
