import SwiftUI

struct SidebarPositionToolbarItem: ToolbarContent {

    @Environment(Unifier.self) var unifier
    @Environment(Orientation.self) var orientation

    var body: some ToolbarContent {
        if UIDevice.current.userInterfaceIdiom != .phone && orientation.isLandscape {
            ToolbarItem(placement: .bottomBar) {
                Button(
                    "Shared.ToggleSidebarPosition",
                    systemImage: unifier.sidebarPosition == .leading ?
                    "sidebar.leading" : "sidebar.trailing"
                ) {
                    unifier.toggleSidebarPosition()
                }
            }
        }
    }
}
