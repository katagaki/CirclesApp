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

        if UIDevice.current.userInterfaceIdiom == .phone {
            ToolbarItem(placement: .topBarLeading) {
                displaySettingsMenu()
            }
        }

        ToolbarSpacer(.fixed, placement: .bottomBar)
        ToolbarItemGroup(placement: .bottomBar) {
            FavoritesColorFilterButton()
            FavoritesHallFilterButton()
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
        if UIDevice.current.userInterfaceIdiom == .phone {
            ToolbarItem(placement: .bottomBar) {
                refreshButton()
            }
        } else {
            ToolbarItemGroup(placement: .bottomBar) {
                displaySettingsMenu()
                refreshButton()
            }
            SidebarPositionToolbarItem()
        }
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
