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

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @Query(sort: [SortDescriptor(\ComiketGenre.id, order: .forward)])
    var genres: [ComiketGenre]

    @Query(sort: [SortDescriptor(\ComiketBlock.id, order: .forward)])
    var blocks: [ComiketBlock]

    @State var selectableMaps: [ComiketMap]?
    @State var selectableBlocks: [ComiketBlock]?
    @State var selectableDates: [ComiketDate]?

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
                    BarAccessoryMenu(LocalizedStringKey(selections.map?.name ?? "Shared.Building"),
                                     icon: "building") {
                        Button("Shared.All") {
                            selections.map = nil
                        }
                        Picker(selection: $selections.map.animation(.smooth.speed(2.0))) {
                            ForEach(selectableMaps ?? maps) { map in
                                Text(map.name)
                                    .tag(map)
                            }
                        } label: {
                            Text("Shared.Building")
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
                    BarAccessoryMenu((selections.date != nil ? "Shared.\(selections.date!.id)th.Day" : "Shared.Day"),
                                     icon: "calendar") {
                        Button("Shared.All") {
                            selections.date = nil
                        }
                        Picker(selection: $selections.date.animation(.smooth.speed(2.0))) {
                            ForEach(selectableDates ?? dates) { date in
                                Text("Shared.\(date.id)th.Day")
                                    .tag(date)
                            }
                        } label: {
                            Text("Shared.Day")
                        }
                    }
                }
                .glassEffect()
            }
            .padding(.horizontal, 12.0)
            .padding(.vertical, 12.0)
        }
        .scrollIndicators(.hidden)
        .onChange(of: selections.map) { _, _ in
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
                selectableMaps = nil
                selectableBlocks = nil
                selectableDates = nil
            }
        } else {
            var selectableMaps: [ComiketMap] = []
            var selectableBlocks: [ComiketBlock] = []
            var selectableDates: [ComiketDate] = []
            maps.forEach { map in
                if displayedCircles.contains(where: {
                    $0.layout?.mapID == map.id
                }) {
                    selectableMaps.append(map)
                }
            }
            blocks.forEach { block in
                if displayedCircles.contains(where: {
                    $0.layout?.blockID == block.id
                }) {
                    selectableBlocks.append(block)
                }
            }
            dates.forEach { date in
                if displayedCircles.contains(where: {
                    $0.day == date.id
                }) {
                    selectableDates.append(date)
                }
            }
            await MainActor.run {
                self.selectableMaps = selectableMaps
                self.selectableBlocks = selectableBlocks
                self.selectableDates = selectableDates
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
