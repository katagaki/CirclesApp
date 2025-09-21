//
//  CatalogToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftData
import SwiftUI

struct CatalogToolbar: View {

    @Environment(Database.self) var database
    @Environment(UserSelections.self) var selections

    @Query(sort: [SortDescriptor(\ComiketGenre.id, order: .forward)])
    var genres: [ComiketGenre]

    @Query(sort: [SortDescriptor(\ComiketBlock.id, order: .forward)])
    var blocks: [ComiketBlock]

    @State var selectableBlocks: [ComiketBlock]?

    @Binding var displayedCircles: [ComiketCircle]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                @Bindable var selections = selections
                Group {
                    BarAccessoryMenu(LocalizedStringKey(selections.genre?.name ?? "Shared.Genre"),
                                     icon: (selections.genre?.name == "ブルーアーカイブ" ?
                                            "scope" : "theatermask.and.paintbrush")) {
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
                    }
                    BarAccessoryMenu(LocalizedStringKey(selections.block?.name ?? "Shared.Block"),
                                     icon: "table.furniture") {
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
                    }
                }
                .glassEffectIfSupported()
            }
            .padding(.horizontal)
            .padding(.vertical, 12.0)
        }
        .scrollIndicators(.hidden)
        .onChange(of: selections.idMap) { _, _ in
            Task.detached {
                await reloadBlocksInMap()
            }
        }
        .onChange(of: displayedCircles) { _, _ in
            Task.detached {
                await reloadSelectableMapsBlocksAndDates()
            }
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
