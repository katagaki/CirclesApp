import SwiftUI

struct SidebarPositionToolbarItem: ToolbarContent {

    @Environment(Unifier.self) var unifier

    var body: some ToolbarContent {
        if unifier.displayMode == .panel && unifier.isPanelSideDocked {
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
