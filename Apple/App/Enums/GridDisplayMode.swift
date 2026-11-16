import Foundation

enum GridDisplayMode: Int, CaseIterable {
    case big = 1
    case medium = 2
    case small = 3

    static let columnRange: ClosedRange<Int> = 3...8
    static let referenceWidth: CGFloat = 440.0

    var columns: Int {
        switch self {
        case .big: return 3
        case .medium: return 5
        case .small: return 8
        }
    }

    init?(columns: Int) {
        guard let mode = Self.allCases.first(where: { $0.columns == columns }) else { return nil }
        self = mode
    }

    init(nearestTo columns: Int) {
        self = Self.allCases.min(by: { abs($0.columns - columns) < abs($1.columns - columns) }) ?? .medium
    }

    static func displayedColumns(_ columns: Int, width: CGFloat) -> Int {
        guard width > referenceWidth else { return columns }
        return max(columns, Int((CGFloat(columns) * width / referenceWidth).rounded()))
    }
}

extension GridDisplayMode {
    static func registerLegacyColumnDefaults() {
        let defaults = UserDefaults.standard
        var registered: [String: Int] = [:]
        for (legacyKey, key) in [("Circles.GridSize", "Circles.GridColumns"),
                                 ("Favorites.GridDisplayMode", "Favorites.GridColumns")] {
            if let mode = GridDisplayMode(rawValue: defaults.integer(forKey: legacyKey)) {
                registered[key] = mode.columns
            }
        }
        defaults.register(defaults: registered)
    }
}
