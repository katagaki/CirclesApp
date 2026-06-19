import SwiftData
import SwiftUI
import AXiS

struct HallPicker: View {
    @Environment(UserSelections.self) var selections
    @Environment(Database.self) var database
    @State var maps: [ComiketMap] = []

    var body: some View {
        Menu {
            ForEach(maps, id: \.id) { map in
                Button(map.name,
                       systemImage: selections.map == map ? "checkmark" : "") {
                    selections.map = map
                }
            }
        } label: {
            HStack(spacing: 10.0) {
                Image(systemName: "building")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20.0)
                if let selectedMap = selections.map {
                    Text(selectedMap.name)
                } else {
                    Text("Shared.Placeholder.NoBlock")
                }
            }
            .padding(.vertical, 12.0)
            .padding(.horizontal, 16.0)
            .foregroundStyle(.white)

        }
        .task {
            maps = database.maps()
        }
    }
}
