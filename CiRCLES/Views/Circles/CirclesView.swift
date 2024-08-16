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
    @State var selectedBlock: ComiketBlock?
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
                    ForEach(displayedCircles) { circle in
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
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Shared.Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        // TODO: Implement filters
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12.0) {
                            Menu {
                                ForEach(database.eventMaps, id: \.id) { map in
                                    Section(map.name) {
                                        ForEach(database.blocks(in: map), id: \.id) { block in
                                            Button(block.name) {
                                                selectedBlock = block
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 8.0) {
                                    Image(systemName: "table.furniture")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18.0, height: 18.0)
                                    Text("Shared.Block")
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding([.top, .bottom], 12.0)
                                .padding([.leading, .trailing], 16.0)
                                .background(.accent)
                            }
                            .buttonStyle(.plain)
                            .clipShape(.capsule)
                        }
                        .padding([.leading, .trailing], 12.0)
                        .padding([.top, .bottom], 12.0)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .searchable(text: $searchTerm,
                        placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: selectedBlock) { _, newValue in
                withAnimation(.snappy.speed(2.0)) {
                    if let newValue {
                        displayedCircles = database.circles(in: newValue).sorted(by: {$0.id < $1.id})
                    } else {
                        displayedCircles.removeAll()
                    }
                }
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                default: Color.clear
                }
            }
        }
    }
}
