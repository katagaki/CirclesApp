//
//  CatalogToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import SwiftData
import SwiftUI

struct CatalogToolbar: ToolbarContent {

    @Environment(Database.self) var database
    @Environment(CatalogCache.self) var catalogCache
    @Environment(UserSelections.self) var selections

    @State var genres: [ComiketGenre] = []
    @State var blocks: [ComiketBlock] = []

    @State var selectableGenres: [ComiketGenre]?
    @State var selectableBlocks: [ComiketBlock]?

    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItemGroup(placement: .bottomBar) {
                genreMenu()
                blockMenu()
            }
        } else {
            ToolbarItem(placement: .bottomBar) {
                genreMenu()
            }
            ToolbarItem(placement: .bottomBar) {
                blockMenu()
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .bottomBar)
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
        } else {
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
        }
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
            database.connect()
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
            case "ブルーアーカイブ":
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
        Menu {
            @Bindable var selections = selections
            Button("Shared.All") {
                self.selections.blocks.removeAll()
            }
            Divider()
            ForEach(selectableBlocks ?? blocks) { block in

                Button {
                    var newBlocks = selections.blocks
                    if newBlocks.contains(block) {
                        newBlocks.remove(block)
                    } else {
                        newBlocks.insert(block)
                    }
                    selections.blocks = newBlocks
                } label: {
                    if selections.blocks.contains(block) {
                        Label(block.name, systemImage: "checkmark")
                    } else {
                        Text(block.name)
                    }
                }
            }
        } label: {
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
        .menuActionDismissBehavior(.disabled)
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

    func reloadSelectableGenres() {
        if let mapID = selections.map?.id, let dayID = selections.date?.id {
            Task {
                database.connect()
                let genreIDs = await CatalogCache.fetchGenreIDs(
                    inMap: mapID,
                    onDay: dayID,
                    database: database.textDatabase
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
        if let mapID = selections.map?.id, let dayID = selections.date?.id {
            let selectedGenreIDs = selections.genres.isEmpty ? nil :
                Array(selections.genres.map({ (genre: ComiketGenre) in genre.id }))

            Task {
                database.connect()
                let blockIDs = await CatalogCache.fetchBlockIDs(
                    inMap: mapID, onDay: dayID, withGenreIDs: selectedGenreIDs, database: database.textDatabase
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
