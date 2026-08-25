import SwiftData
import SwiftUI
import AXiS

struct CatalogToolbar: ToolbarContent {

    @Environment(Database.self) var database
    @Environment(CatalogCache.self) var catalogCache
    @Environment(UserSelections.self) var selections

    @State var genres: [ComiketGenre] = []
    @State var blocks: [ComiketBlock] = []

    @State var selectableGenres: [ComiketGenre]?
    @State var selectableBlocks: [ComiketBlock]?

    @State var isBlockPopoverPresented: Bool = false

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            genreMenu()
            blockMenu()
        }
        ToolbarSpacer(.fixed, placement: .bottomBar)
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
    }

    @ViewBuilder
    func genreMenu() -> some View {
        Menu {
            @Bindable var selections = selections
            Button("Shared.All") {
                self.selections.genres.removeAll()
            }
            Divider()
            ForEach(selectableGenres ?? genres) { genre in

                Button {
                    var newGenres = selections.genres
                    if newGenres.contains(genre) {
                        newGenres.remove(genre)
                    } else {
                        newGenres.insert(genre)
                    }
                    selections.genres = newGenres
                } label: {
                    if selections.genres.contains(genre) {
                        Label(genre.name, systemImage: "checkmark")
                    } else {
                        Text(genre.name)
                    }
                }
            }
        } label: {
            genreIcon(selections.genres)
        }
        .menuActionDismissBehavior(.disabled)
        .onChange(of: selections.map, initial: true) {
            reloadSelectableGenres()
        }
        .onChange(of: selections.date, initial: true) {
            reloadSelectableGenres()
        }
        .task {
            genres = database.genres()
            blocks = database.blocks()
        }

    }

    @ViewBuilder
    func genreIcon(_ genres: Set<ComiketGenre>) -> some View {
        if genres.count == 1, let firstGenre = genres.first {
            let genreName = firstGenre.name
            switch genreName {
            case "男性向":
                ToolbarButtonLabel(
                    LocalizedStringKey(genreName),
                    image: .asset("Button.R18")
                )
            case "ブルーアーカイブ":
                ToolbarButtonLabel(
                    LocalizedStringKey(genreName),
                    image: .system("scope")
                )
            case "艦これ", "アズールレーン":
                ToolbarButtonLabel(
                    LocalizedStringKey(genreName),
                    image: .system("water.waves")
                )
            case "コスプレ":
                ToolbarButtonLabel(
                    LocalizedStringKey(genreName),
                    image: .system("tshirt")
                )
            default:
                ToolbarButtonLabel(
                    LocalizedStringKey(genreName),
                    image: .system("theatermask.and.paintbrush")
                )
            }
        } else if genres.count > 1 {
            ToolbarButtonLabel(
                "Shared.Genre.Multiple",
                image: .system("theatermask.and.paintbrush")
            )
        } else {
            ToolbarButtonLabel(
                "Shared.Genre",
                image: .system("theatermask.and.paintbrush")
            )
        }
    }

    @ViewBuilder
    func blockMenu() -> some View {
        Button {
            isBlockPopoverPresented = true
        } label: {
            blockLabel()
        }
        .popover(isPresented: $isBlockPopoverPresented) {
            blockPopover()
                .presentationCompactAdaptation(.popover)
        }
        .onChange(of: selections.map, initial: true) {
            reloadSelectableBlocks()
        }
        .onChange(of: selections.date, initial: true) {
            reloadSelectableBlocks()
        }
        .onChange(of: selections.genres) {
            reloadSelectableBlocks()
        }
    }

    @ViewBuilder
    func blockLabel() -> some View {
        if selections.blocks.count == 1, let firstBlock = selections.blocks.first {
            ToolbarButtonLabel(
                LocalizedStringKey(firstBlock.name),
                image: .system("rectangle.split.3x1")
            )
        } else if selections.blocks.count > 1 {
            ToolbarButtonLabel(
                "Shared.Block.Multiple",
                image: .system("rectangle.split.3x1")
            )
        } else {
            ToolbarButtonLabel(
                "Shared.Block",
                image: .system("rectangle.split.3x1")
            )
        }
    }

    @ViewBuilder
    func blockPopover() -> some View {
        VStack(alignment: .leading, spacing: 16.0) {
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: .init(.flexible(), spacing: 8.0),
                        count: 4
                    ),
                    spacing: 8.0
                ) {
                    ForEach(selectableBlocks ?? blocks) { block in
                        let isSelected = selections.blocks.contains(block)
                        Button {
                            withAnimation(.smooth.speed(2.0)) {
                                var newBlocks = selections.blocks
                                if isSelected {
                                    newBlocks.remove(block)
                                } else {
                                    newBlocks.insert(block)
                                }
                                selections.blocks = newBlocks
                            }
                        } label: {
                            Text(block.name)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(isSelected ? Color.white : Color.primary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    isSelected ? Color.accentColor : Color.primary.opacity(0.1),
                                    in: .rect(cornerRadius: 20.0)
                                )
                                .aspectRatio(1.0, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding([.horizontal, .top])
            }
            .frame(minHeight: 200.0, maxHeight: 360.0)
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    selections.blocks.removeAll()
                }
            } label: {
                Text("Shared.All")
                    .fontWeight(.bold)
                    .padding(.vertical, 2.0)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(selections.blocks.isEmpty)
            .padding([.horizontal, .bottom])
        }
        .frame(width: 280.0)
    }

    func reloadSelectableGenres() {
        if genres.isEmpty {
            genres = database.genres()
        }
        if let mapID = selections.map?.id, let dayID = selections.date?.id {
            Task {
                let genreIDs = await CatalogCache.fetchGenreIDs(
                    inMap: mapID,
                    onDay: dayID,
                    database: database
                )
                await MainActor.run {
                    withAnimation(.smooth.speed(2.0)) {
                        selectableGenres = genres
                            .filter({ genreIDs.contains($0.id) })
                            .sorted(by: {$0.name < $1.name})
                    }
                }
            }
        } else {
            selectableGenres = nil
        }
    }

    func reloadSelectableBlocks() {
        if blocks.isEmpty {
            blocks = database.blocks()
        }
        if let mapID = selections.map?.id, let dayID = selections.date?.id {
            let selectedGenreIDs = selections.genres.isEmpty ? nil :
                Array(selections.genres.map({ (genre: ComiketGenre) in genre.id }))

            Task {
                let blockIDs = await CatalogCache.fetchBlockIDs(
                    inMap: mapID, onDay: dayID, withGenreIDs: selectedGenreIDs, database: database
                )
                await MainActor.run {
                    withAnimation(.smooth.speed(2.0)) {
                        selectableBlocks = blocks
                            .filter({ blockIDs.contains($0.id) })
                            .sorted(by: {$0.name < $1.name})
                    }
                }
            }
        } else {
            selectableBlocks = nil
        }
    }

}
