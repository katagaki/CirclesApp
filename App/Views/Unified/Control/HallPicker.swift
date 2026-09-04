import SwiftData
import SwiftUI
import AXiS

struct HallPicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.25)) {
                unifier.presentedControlMenu = .hall
            }
        } label: {
            Group {
                if let selectedMap = selections.map {
                    Text(selectedMap.name)
                } else {
                    Text("Shared.Placeholder.NoBlock")
                }
            }
            .padding(.vertical, 8.0)
            .padding(.horizontal, 16.0)
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

struct HallMinimapMenu: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database

    let minimapWidth: CGFloat = 268.0

    var maps: [ComiketMap] {
        database.maps()
    }

    var body: some View {
        ControlMenu(contentWidth: minimapWidth) { close in
            HallMinimap(maps: maps, selection: selections.map, width: minimapWidth) { map in
                selections.map = map
                close()
            }
        }
    }
}
