//
//  CircleFilterBar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftData
import SwiftUI

struct CircleFilterBar: View {

    @Environment(Database.self) var database

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @Query(sort: [SortDescriptor(\ComiketGenre.id, order: .forward)])
    var genres: [ComiketGenre]

    @Query(sort: [SortDescriptor(\ComiketBlock.id, order: .forward)])
    var blocks: [ComiketBlock]

    @Binding var selectedGenre: ComiketGenre?
    @Binding var selectedMap: ComiketMap?
    @Binding var selectedBlock: ComiketBlock?
    @Binding var selectedDate: ComiketDate?

    @AppStorage(wrappedValue: 0, "Circles.SelectedGenreID") var selectedGenreID: Int
    @AppStorage(wrappedValue: 0, "Circles.SelectedMapID") var selectedMapID: Int
    @AppStorage(wrappedValue: 0, "Circles.SelectedBlockID") var selectedBlockID: Int
    @AppStorage(wrappedValue: 0, "Circles.SelectedDateID") var selectedDateID: Int

    @State var blocksInMap: [ComiketBlock] = []

    @State var isInitialLoadCompleted: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12.0) {
                BarAccessoryMenu(LocalizedStringKey(selectedGenre?.name ?? "Shared.Genre"),
                                 icon: (selectedGenre?.name == "ブルーアーカイブ" ?
                                        "scope" : "theatermask.and.paintbrush")) {
                    Picker(selection: $selectedGenre.animation(.snappy.speed(2.0))) {
                        Text("Shared.All")
                            .tag(nil as ComiketGenre?)
                        ForEach(genres) { genre in
                            Text(genre.name)
                                .tag(genre)
                        }
                    } label: {
                        Text("Shared.Genre")
                    }
                }
                BarAccessoryMenu(LocalizedStringKey(selectedMap?.name ?? "Shared.Map"),
                                 icon: "map") {
                    Picker(selection: $selectedMap.animation(.snappy.speed(2.0))) {
                        Text("Shared.All")
                            .tag(nil as ComiketMap?)
                        ForEach(maps) { map in
                            Text(map.name)
                                .tag(map)
                        }
                    } label: {
                        Text("Shared.Map")
                    }
                }
                if selectedMap != nil {
                    BarAccessoryMenu(LocalizedStringKey(selectedBlock?.name ?? "Shared.Block"),
                                     icon: "table.furniture") {
                        Picker(selection: $selectedBlock.animation(.snappy.speed(2.0))) {
                            Text("Shared.All")
                                .tag(nil as ComiketBlock?)
                            ForEach(blocksInMap, id: \.id) { block in
                                Text(block.name)
                                    .tag(block)
                            }
                        } label: {
                            Text("Shared.Block")
                        }
                    }
                }
                BarAccessoryMenu((selectedDate != nil ? "Shared.\(selectedDate!.id)th.Day" : "Shared.Day"),
                                 icon: "calendar") {
                    Picker(selection: $selectedDate.animation(.snappy.speed(2.0))) {
                        Text("Shared.All")
                            .tag(nil as ComiketDate?)
                        ForEach(dates) { date in
                            Text("Shared.\(date.id)th.Day")
                                .tag(date)
                        }
                    } label: {
                        Text("Shared.Day")
                    }
                }
            }
            .padding([.leading, .trailing], 12.0)
            .padding([.top, .bottom], 12.0)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if !isInitialLoadCompleted {
                selectedGenre = genres.first(where: {$0.id == selectedGenreID})
                selectedMap = maps.first(where: {$0.id == selectedMapID})
                selectedBlock = blocks.first(where: {$0.id == selectedBlockID})
                selectedDate = dates.first(where: {$0.id == selectedDateID})
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: selectedGenre) { _, _ in
            if isInitialLoadCompleted {
                selectedGenreID = selectedGenre?.id ?? 0
            }
        }
        .onChange(of: selectedMap) { oldValue, newValue in
            if isInitialLoadCompleted {
                selectedMapID = selectedMap?.id ?? 0
                if oldValue != newValue && oldValue != nil {
                    selectedBlock = nil
                }
                Task.detached {
                    await reloadBlocksInMap()
                }
            }
        }
        .onChange(of: selectedBlock) { _, _ in
            if isInitialLoadCompleted {
                selectedBlockID = selectedBlock?.id ?? 0
            }
        }
        .onChange(of: selectedDate) { _, _ in
            if isInitialLoadCompleted {
                selectedDateID = selectedDate?.id ?? 0
            }
        }
    }

    func reloadBlocksInMap() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        let blockIdentifiers = await actor.blocks(inMap: selectedMapID)
        await MainActor.run {
            self.blocksInMap = database.blocks(blockIdentifiers)
        }
    }
}
