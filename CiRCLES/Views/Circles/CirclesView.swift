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

    let gridSpacing: CGFloat = 1.0

    @State var displayedCircles: [ComiketCircle] = []
    @State var searchedCircles: [ComiketCircle]?

    @State var selectedBlock: ComiketBlock?
    @State var selectedDate: ComiketDate?

    @State var searchTerm: String = ""

    var body: some View {

        let phoneColumnConfiguration = [GridItem(.adaptive(minimum: 60.0), spacing: gridSpacing)]
    #if targetEnvironment(macCatalyst)
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 60.0), spacing: gridSpacing)]
    #else
        let padOrMacColumnConfiguration = [GridItem(.adaptive(minimum: 100.0), spacing: gridSpacing)]
    #endif

        NavigationStack(path: $navigationManager[.circles]) {
            ScrollView {
                LazyVGrid(columns: UIDevice.current.userInterfaceIdiom == .phone ?
                          phoneColumnConfiguration : padOrMacColumnConfiguration,
                          spacing: gridSpacing) {
                    ForEach(searchedCircles == nil ? displayedCircles : searchedCircles ?? []) { circle in
                        NavigationLink(value: ViewPath.circlesDetail(circle: circle)) {
                            if let image = database.circleImage(for: circle.id) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Text(circle.circleName)
                            }
                        }
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
        if let selectedBlock {
            var newDisplayedCircles = database.circles(in: selectedBlock).sorted(by: {$0.id < $1.id})
            if let selectedDate {
                newDisplayedCircles.removeAll(where: { $0.day != selectedDate.id })
            }
            displayedCircles = newDisplayedCircles
        } else {
            displayedCircles.removeAll()
        }
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
