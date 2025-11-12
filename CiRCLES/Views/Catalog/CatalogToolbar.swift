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

    @Query(sort: [SortDescriptor(\ComiketGenre.id, order: .forward)])
    var genres: [ComiketGenre]

    @Query(sort: [SortDescriptor(\ComiketBlock.id, order: .forward)])
    var blocks: [ComiketBlock]

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
                self.selections.genre = nil
            }
            Picker(selection: $selections.genre.animation(.smooth.speed(2.0))) {
                ForEach(selectableGenres ?? genres, id: \.id) { genre in
                    Text(genre.name)
                        .tag(genre)
                }
            } label: {
                Text("Shared.Genre")
            }
        } label: {
            genreIcon(selections.genre?.name)
        }
        .onChange(of: catalogCache.displayedCircles.hashValue, initial: true) {
            reloadSelectableGenres()
        }
    }

    @ViewBuilder
    func genreIcon(_ genreName: String?) -> some View {
        switch genreName {
        case "男性向":
            ToolbarButtonLabel(
                LocalizedStringKey(genreName ?? "Shared.Genre"),
                image: .asset("Button.R18")
            )
        case "ブルーアーカイブ":
            ToolbarButtonLabel(
                LocalizedStringKey(genreName ?? "Shared.Genre"),
                image: .system("scope")
            )
        case "艦これ", "アズールレーン":
            ToolbarButtonLabel(
                LocalizedStringKey(genreName ?? "Shared.Genre"),
                image: .system("water.waves")
            )
        case "コスプレ":
            ToolbarButtonLabel(
                LocalizedStringKey(genreName ?? "Shared.Genre"),
                image: .system("tshirt")
            )
        default:
            ToolbarButtonLabel(
                LocalizedStringKey(genreName ?? "Shared.Genre"),
                image: .system("theatermask.and.paintbrush")
            )
        }
    }

    @ViewBuilder
    func blockMenu() -> some View {
        Menu {
            @Bindable var selections = selections
            Button("Shared.All") {
                self.selections.block = nil
            }
            Picker(selection: $selections.block.animation(.smooth.speed(2.0))) {
                ForEach(selectableBlocks ?? blocks, id: \.id) { block in
                    Text(block.name)
                        .tag(block)
                }
            } label: {
                Text("Shared.Block")
            }
        } label: {
            ToolbarButtonLabel(
                LocalizedStringKey(selections.block?.name ?? "Shared.Block"),
                image: .system("rectangle.split.3x1")
            )
        }
        .onChange(of: catalogCache.displayedCircles.hashValue, initial: true) {
            reloadSelectableBlocks()
        }
    }

    func reloadSelectableGenres() {
        if catalogCache.displayedCircles.isEmpty {
            selectableGenres = nil
        } else {
            let genreIDs: [Int] = Array(Set(catalogCache.displayedCircles.compactMap({$0.genreID})))
            selectableGenres = genres.filter({ genreIDs.contains($0.id) })
        }
    }

    func reloadSelectableBlocks() {
        if catalogCache.displayedCircles.isEmpty {
            selectableBlocks = nil
        } else {
            let blockIDs: [Int] = Array(Set(catalogCache.displayedCircles.compactMap({$0.blockID})))
            selectableBlocks = blocks.filter({ blockIDs.contains($0.id) })
        }
    }
}
