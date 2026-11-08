import SwiftUI

extension Unifier {

    /// Route screens open inside the panel, raised to full height, rather than as sheets of
    /// their own: the panel is already a sheet, and a second one would be dropped.
    @MainActor
    func openRouteScreen(_ path: UnifiedPath) {
        append(path)
        selectedDetent = .large
    }

    @MainActor
    func closeRouteScreen(_ path: UnifiedPath) {
        closePanelScreen(path)
        selectedDetent = .height(360)
    }

    @MainActor
    func closePanelScreen(_ path: UnifiedPath) {
        if sheetPath.last == path {
            sheetPath.removeLast()
        } else if current == path {
            current = .circles
        }
    }
}
