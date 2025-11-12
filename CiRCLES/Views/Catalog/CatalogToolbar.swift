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
    @Environment(UserSelections.self) var selections

    @Query(sort: [SortDescriptor(\ComiketGenre.id, order: .forward)])
    var genres: [ComiketGenre]

    @Query(sort: [SortDescriptor(\ComiketBlock.id, order: .forward)])
    var blocks: [ComiketBlock]

    @State var selectableBlocks: [ComiketBlock]?

    @Binding var displayedCircles: [ComiketCircle]

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
                selections.genre = nil
            }
            Picker(selection: $selections.genre.animation(.smooth.speed(2.0))) {
                ForEach(genres) { genre in
                    Text(genre.name)
                        .tag(genre)
                }
            } label: {
                Text("Shared.Genre")
            }
        } label: {
            switch selections.genre?.name {
            case "男性向":
                ToolbarButtonLabel(
                    LocalizedStringKey(selections.genre?.name ?? "Shared.Genre"),
                    image: .asset("Button.R18")
                )
            case "ブルーアーカイブ":
                ToolbarButtonLabel(
                    LocalizedStringKey(selections.genre?.name ?? "Shared.Genre"),
                    image: .system("scope")
                )
            case "艦これ", "アズールレーン":
                ToolbarButtonLabel(
                    LocalizedStringKey(selections.genre?.name ?? "Shared.Genre"),
                    image: .system("water.waves")
                )
            case "コスプレ":
                ToolbarButtonLabel(
                    LocalizedStringKey(selections.genre?.name ?? "Shared.Genre"),
                    image: .system("tshirt")
                )
            default:
                ToolbarButtonLabel(
                    LocalizedStringKey(selections.genre?.name ?? "Shared.Genre"),
                    image: .system("theatermask.and.paintbrush")
                )
            }
        }
        .onChange(of: selections.fullMapID) {
            Task.detached {
                await reloadBlocksInMap()
            }
        }
        .onChange(of: displayedCircles) {
            Task.detached {
                await reloadSelectableMapsBlocksAndDates()
            }
        }
    }

    @ViewBuilder
    func blockMenu() -> some View {
        Menu {
            @Bindable var selections = selections
            Button("Shared.All") {
                selections.block = nil
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
    }

    func reloadSelectableMapsBlocksAndDates() async {
        if displayedCircles.isEmpty {
            await MainActor.run {
                selectableBlocks = nil
            }
        } else {
            var selectableBlocks: [ComiketBlock] = []
            blocks.forEach { block in
                if displayedCircles.contains(where: {
                    $0.layout?.blockID == block.id
                }) {
                    selectableBlocks.append(block)
                }
            }
            await MainActor.run {
                self.selectableBlocks = selectableBlocks
            }
        }
    }

    func reloadBlocksInMap() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        if let selectedMap = selections.map {
            let blockIdentifiers = await actor.blocks(inMap: selectedMap.id)
            await MainActor.run {
                self.selectableBlocks = database.blocks(blockIdentifiers)
            }
        } else {
            self.selectableBlocks = []
        }
    }
}
