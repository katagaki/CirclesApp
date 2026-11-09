import SwiftData
import SwiftUI
import AXiS

struct FavoritesToolbar: ToolbarContent {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites

    @Binding var displayMode: CircleDisplayMode
    @Binding var listDisplayMode: ListDisplayMode
    @Binding var gridDisplayMode: GridDisplayMode

    var body: some ToolbarContent {

        ToolbarSpacer(.fixed, placement: .bottomBar)
        ToolbarItemGroup(placement: .bottomBar) {
            FavoritesColorFilterButton()
            FavoritesHallFilterButton()
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            refreshButton()
        }
        ToolbarSpacer(.fixed, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            displaySettingsMenu()
        }
        SidebarPositionToolbarItem()
    }

    @ViewBuilder
    func refreshButton() -> some View {
        Button {
            Task { await favorites.refresh(authToken: authenticator.token) }
        } label: {
            if favorites.isRefreshing {
                ProgressView()
            } else {
                ToolbarButtonLabel("Shared.Refresh", image: .system("arrow.clockwise"))
            }
        }
        .labelStyle(.iconOnly)
        .disabled(authenticator.isOfflineModeActive || favorites.isRefreshing)
    }

    @ViewBuilder
    func displaySettingsMenu() -> some View {
        DisplaySettingsMenu(
            displayMode: $displayMode,
            listDisplayMode: $listDisplayMode,
            gridDisplayMode: $gridDisplayMode
        )
    }
}
