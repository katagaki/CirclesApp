import Foundation

enum SharedState {

    static let appGroup = "group.com.tsubuzaki.circlesproto"

    private static let visitedKey = "Shared.VisitedIDs"
    private static let dayKey = "Shared.Day"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var isSharedContainerAvailable: Bool {
        UserDefaults(suiteName: appGroup) != nil
            && FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
    }

    static var visitedIDs: Set<Int> {
        get { Set(defaults.array(forKey: visitedKey) as? [Int] ?? []) }
        set { defaults.set(Array(newValue), forKey: visitedKey) }
    }

    static var day: Int {
        get { defaults.object(forKey: dayKey) as? Int ?? 1 }
        set { defaults.set(newValue, forKey: dayKey) }
    }
}
