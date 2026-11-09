import Foundation

struct ToolbeltLayers: Equatable {
    var showsFavorites = true
    var showsVisited = true
    var showsGenres = false

    var isDefault: Bool { self == ToolbeltLayers() }
}
