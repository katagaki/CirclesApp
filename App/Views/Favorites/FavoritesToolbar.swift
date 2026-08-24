import SwiftData
import SwiftUI
import AXiS

struct FavoritesToolbar: ToolbarContent {

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
            ToolbarSpacer(.fixed, placement: .bottomBar)
        } else {
            ToolbarItem(placement: .bottomBar) {
                displaySettingsMenu()
            }
            SidebarPositionToolbarItem()
        }
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
