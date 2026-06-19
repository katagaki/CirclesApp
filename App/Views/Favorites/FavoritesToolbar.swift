import SwiftData
import SwiftUI

struct FavoritesToolbar: ToolbarContent {
    @Environment(Favorites.self) var favorites

    @Binding var displayMode: CircleDisplayMode
    @Binding var listDisplayMode: ListDisplayMode
    @Binding var gridDisplayMode: GridDisplayMode

    var body: some ToolbarContent {

        ToolbarItem(placement: .topBarLeading) {
            DisplaySettingsMenu(
                displayMode: $displayMode,
                listDisplayMode: $listDisplayMode,
                gridDisplayMode: $gridDisplayMode
            )
        }

        ToolbarSpacer(.fixed, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    favorites.isGroupedByColor.toggle()
                }
            } label: {
                ToolbarButtonLabel(
                    "Shared.GroupByColor",
                    image: .system(favorites.isGroupedByColor ?
                    "paintpalette.fill" : "paintpalette"),
                    forceLabelStyle: true
                )
            }
        }
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarSpacer(.fixed, placement: .bottomBar)
    }
}
