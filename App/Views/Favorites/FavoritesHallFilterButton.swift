import SwiftUI
import AXiS

struct FavoritesHallFilterButton: View {

    @Environment(Database.self) var database
    @EnvironmentObject var filters: FavoritesFilters

    @State var maps: [ComiketMap] = []
    @State var isPopoverPresented: Bool = false

    var body: some View {
        Button {
            reloadMaps()
            isPopoverPresented = true
        } label: {
            label()
        }
        .popover(isPresented: $isPopoverPresented) {
            popover()
                .presentationCompactAdaptation(.popover)
                .task {
                    reloadMaps()
                }
        }
        .task {
            reloadMaps()
        }
    }

    func reloadMaps() {
        let maps = database.maps()
        if !maps.isEmpty {
            self.maps = maps
        }
    }

    @ViewBuilder
    func label() -> some View {
        if filters.halls.count == 1, let firstHall = filters.halls.first,
           let map = maps.first(where: { $0.id == firstHall }) {
            ToolbarButtonLabel(
                LocalizedStringKey(map.name),
                image: .system("building")
            )
        } else if filters.halls.count > 1 {
            ToolbarButtonLabel(
                "Shared.Building.Multiple",
                image: .system("building")
            )
        } else {
            ToolbarButtonLabel(
                "Shared.Building",
                image: .system("building")
            )
        }
    }

    @ViewBuilder
    func popover() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                LazyVGrid(
                    columns: [.init(.flexible(), spacing: 8.0),
                              .init(.flexible(), spacing: 8.0)],
                    spacing: 8.0
                ) {
                    ForEach(maps, id: \.id) { map in
                        let isSelected = filters.halls.contains(map.id)
                        Button {
                            withAnimation(.smooth.speed(2.0)) {
                                if isSelected {
                                    filters.halls.remove(map.id)
                                } else {
                                    filters.halls.insert(map.id)
                                }
                            }
                        } label: {
                            Text(map.name)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14.0)
                                .background(
                                    isSelected ? Color.accentColor : Color.primary.opacity(0.1),
                                    in: .rect(cornerRadius: 20.0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    withAnimation(.smooth.speed(2.0)) {
                        filters.halls.removeAll()
                    }
                } label: {
                    Text("Shared.All")
                        .fontWeight(.bold)
                        .padding(.vertical, 2.0)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(filters.halls.isEmpty)
            }
            .padding()
            .frame(width: 240.0)
        }
    }
}
