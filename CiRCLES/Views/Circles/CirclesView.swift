//
//  CirclesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftUI

struct CirclesView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(EventManager.self) var eventManager
    @Environment(DatabaseManager.self) var database

    @State var displayedCircles: [ComiketCircle] = []
    @State var searchedCircles: [ComiketCircle]?

    @State var selectedBlock: ComiketBlock?
    @State var selectedDate: ComiketDate?
    @State var selectedGenre: ComiketGenre?

    @State var searchTerm: String = ""

    var body: some View {
        NavigationStack(path: $navigationManager[.circles]) {
            Group {
                if let searchedCircles {
                    CircleGrid(circles: searchedCircles) { circle in
                        navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                    }
                } else {
                    CircleGrid(circles: displayedCircles) { circle in
                        navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                    }
                }
            }
            .navigationTitle("ViewTitle.Circles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                if selectedBlock == nil {
                    ContentUnavailableView(
                        "Circles.NoFilterSelected",
                        systemImage: "questionmark.square.dashed",
                        description: Text("Circles.NoFilterSelected.Description")
                    )
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12.0) {
                            BarAccessoryMenu("Shared.Genre", icon: "theatermask.and.paintbrush") {
                                Picker(selection: $selectedGenre) {
                                    Text("Shared.All")
                                        .tag(nil as ComiketGenre?)
                                    ForEach(database.eventGenres, id: \.id) { genre in
                                        Text(genre.name)
                                            .tag(genre)
                                    }
                                } label: {
                                    Text("Shared.Genre")
                                }
                            }
                            BarAccessoryMenu("Shared.Block", icon: "table.furniture") {
                                ForEach(database.eventMaps, id: \.id) { map in
                                    Picker(selection: $selectedBlock) {
                                        ForEach(database.blocks(in: map), id: \.id) { block in
                                            Text(block.name)
                                                .tag(block)
                                        }
                                    } label: {
                                        Text(map.name)
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            BarAccessoryMenu("Shared.Day", icon: "calendar") {
                                Picker(selection: $selectedDate) {
                                    Text("Shared.All")
                                        .tag(nil as ComiketDate?)
                                    ForEach(database.eventDates, id: \.id) { date in
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
                }
            }
            .searchable(text: $searchTerm, placement: .navigationBarDrawer(displayMode: .always), prompt: "Circles.Search.Prompt")
            .onChange(of: selectedGenre) { _, _ in
                reloadDisplayedCircles()
            }
            .onChange(of: selectedBlock) { _, _ in
                reloadDisplayedCircles()
            }
            .onChange(of: selectedDate) { _, _ in
                reloadDisplayedCircles()
            }
            .onChange(of: searchTerm) { _, _ in
                searchCircles()
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                default: Color.clear
                }
            }
        }
    }

    func reloadDisplayedCircles() {
        var displayedCircles: [ComiketCircle] = []
        if let selectedGenre {
            displayedCircles = database.circles(with: selectedGenre)
        }
        if let selectedBlock {
            var circlesInSelectedBlock = database.circles(in: selectedBlock).sorted(by: {$0.id < $1.id})
            if let selectedDate {
                circlesInSelectedBlock.removeAll(where: { $0.day != selectedDate.id })
            }
            displayedCircles.removeAll(where: {
                !circlesInSelectedBlock.contains($0)
            })
        }
        self.displayedCircles = displayedCircles
    }

    func searchCircles() {
        let searchTermLowercased = searchTerm.lowercased()
        if searchTerm.trimmingCharacters(in: .whitespaces).count > 2 {
            searchedCircles = database.eventCircles.filter({
                $0.circleName.lowercased().contains(searchTermLowercased) ||
                $0.circleNameKana.lowercased().contains(searchTermLowercased) ||
                $0.penName.lowercased().contains(searchTermLowercased)
            })
        } else {
            searchedCircles = nil
        }
    }
}
