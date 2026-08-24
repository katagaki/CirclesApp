import SwiftUI
import RADiUS

struct FavoritesColorFilterButton: View {

    @Environment(Favorites.self) var favorites
    @EnvironmentObject var filters: FavoritesFilters

    @State var isPopoverPresented: Bool = false

    var colors: [WebCatalogColor] {
        if filters.hasUncoloredFavorites {
            return [.uncolored] + WebCatalogColor.assignable
        }
        return WebCatalogColor.assignable
    }

    var colorGridHeight: CGFloat {
        let rows = CGFloat((colors.count + 3) / 4)
        return (rows * 56.0) + ((rows - 1) * 8.0)
    }

    var body: some View {
        Button {
            isPopoverPresented = true
        } label: {
            label()
        }
        .popover(isPresented: $isPopoverPresented) {
            popover()
                .presentationCompactAdaptation(.popover)
        }
    }

    @ViewBuilder
    func label() -> some View {
        if filters.colors.count == 1,
           let firstColor = filters.colors.first,
           let color = WebCatalogColor(rawValue: firstColor) {
            ToolbarButtonLabel(
                LocalizedStringKey(color.name()),
                image: .system("paintpalette")
            )
        } else if filters.colors.count > 1 {
            ToolbarButtonLabel(
                "Shared.Color.Multiple",
                image: .system("paintpalette")
            )
        } else {
            ToolbarButtonLabel(
                "Shared.Color",
                image: .system("paintpalette")
            )
        }
    }

    @ViewBuilder
    func popover() -> some View {
        @Bindable var favorites = favorites

        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                VStack(alignment: .leading, spacing: 8.0) {
                    Text("Shared.SelectColor")
                        .fontWeight(.semibold)
                    LazyVGrid(
                        columns: [.init(.fixed(56.0), spacing: 8.0),
                                  .init(.fixed(56.0), spacing: 8.0),
                                  .init(.fixed(56.0), spacing: 8.0),
                                  .init(.fixed(56.0), spacing: 8.0)],
                        spacing: 8.0
                    ) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                withAnimation(.smooth.speed(2.0)) {
                                    if filters.colors.contains(color.rawValue) {
                                        filters.colors.remove(color.rawValue)
                                    } else {
                                        filters.colors.insert(color.rawValue)
                                    }
                                }
                            } label: {
                                color.backgroundColor()
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .clipShape(.circle)
                                    .overlay {
                                        Circle()
                                            .stroke(Color.primary.opacity(0.3))
                                    }
                                    .overlay {
                                        if filters.colors.contains(color.rawValue) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(color.foregroundColor())
                                                .font(.title3)
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: colorGridHeight)
                }
                Toggle(isOn: $favorites.isGroupedByColor.animation(.smooth.speed(2.0))) {
                    Text("Shared.GroupByColor")
                        .fontWeight(.semibold)
                }
                Button {
                    withAnimation(.smooth.speed(2.0)) {
                        filters.colors.removeAll()
                    }
                } label: {
                    Text("Shared.All")
                        .fontWeight(.bold)
                        .padding(.vertical, 2.0)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(filters.colors.isEmpty)
            }
            .padding()
        }
    }
}
