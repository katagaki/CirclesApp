import CoreGraphics
import Foundation
import RADiUS

/// A Guide session as it stood when last changed, kept on disk so it can be picked up
/// again after the app is closed.
nonisolated struct GuideSession: Codable, Sendable {
    let eventNumber: Int
    let mapID: Int
    let day: Int
    let favoriteColors: [Int: WebCatalogColor]
    let visitedCircleIDs: [Int]
    let colorPriority: [WebCatalogColor]?
    let route: PlannedRoute?
    let stepIndex: Int
    let origin: CGPoint?
    let closures: [RouteClosure]
    let skippedSpaces: [String]
    let remainingStopIDs: Set<Int>?
    let isTrapped: Bool
    let isFinished: Bool

    private static var url: URL {
        URL.applicationSupportDirectory.appending(path: "GuideSession.json")
    }

    static func load() -> GuideSession? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GuideSession.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? FileManager.default.createDirectory(
            at: URL.applicationSupportDirectory, withIntermediateDirectories: true
        )
        try? data.write(to: Self.url, options: .atomic)
    }

    static func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
