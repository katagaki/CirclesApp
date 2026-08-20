import CoreGraphics
import Foundation

@MainActor
enum HitTestSelfCheck {

    static func runIfRequested(store: CatalogStore) {
        guard UserDefaults.standard.bool(forKey: "Prototype.SelfTest") else { return }

        print("SELFTEST begin")
        print("SELFTEST appGroupAvailable=\(SharedState.isSharedContainerAvailable)")
        for favorite in store.favorites.prefix(12) {
            guard let rect = store.rect(for: favorite.circle) else {
                print("SELFTEST \(favorite.spaceLabel) FAIL no rect")
                continue
            }
            let probe = CGPoint(x: rect.midX, y: rect.midY)
            let hit = store.circle(at: probe, mapID: favorite.mapID, on: favorite.circle.day)
            let label = hit.map { "\(store.blockName($0.blockID))\($0.spaceNumberCombined)" } ?? "nil"
            let verdict = hit?.id == favorite.circle.id ? "PASS" : "FAIL"
            print("SELFTEST \(verdict) expected=\(favorite.spaceLabel) got=\(label) probe=\(probe)")
        }

        let empty = store.circle(at: CGPoint(x: 5.0, y: 5.0), mapID: 1, on: 1)
        print("SELFTEST \(empty == nil ? "PASS" : "FAIL") offMapProbeReturnsNil")
        print("SELFTEST end")
    }
}
