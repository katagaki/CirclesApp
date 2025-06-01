//
//  MapView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import Komponents
import SwiftData
import SwiftUI

struct MapView: View {

    @EnvironmentObject var navigator: Navigator<TabType, ViewPath>
    @Environment(Orientation.self) var orientation
    @Environment(Database.self) var database

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @AppStorage(wrappedValue: 0, "Map.SelectedDateID") var selectedDateID: Int
    @AppStorage(wrappedValue: 0, "Map.SelectedMapID") var selectedMapID: Int
    @State var selectedDate: ComiketDate?
    @State var selectedMap: ComiketMap?

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    @State var isInitialLoadCompleted: Bool = false

    @Namespace var mapNamespace

    var body: some View {
        NavigationStack(path: $navigator[.map]) {
            InteractiveMap(
                date: $selectedDate,
                map: $selectedMap,
                namespace: mapNamespace
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if !targetEnvironment(macCatalyst)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ViewTitle.Map")
            #endif
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    ToolbarItem(placement: .principal) {
                        Color.clear
                    }
                }
            }
            .overlay {
                #if !os(visionOS)
                if orientation.isLandscapeOrUpsideDown() {
                    ZStack(alignment: .bottomLeading) {
                        SquareButtonStack {
                            Menu {
                                ForEach(dates, id: \.id) { date in
                                    Section("Shared.\(date.id)th.Day") {
                                        ForEach(maps, id: \.id) { map in
                                            Button {
                                                withAnimation(.snappy.speed(2.0)) {
                                                    selectedDate = date
                                                    selectedMap = map
                                                }
                                            } label: {
                                                if selectedDate == date && selectedMap == map {
                                                    Label(LocalizedStringKey(stringLiteral: map.name),
                                                          systemImage: "checkmark")
                                                } else {
                                                    Text(LocalizedStringKey(stringLiteral: map.name))
                                                }
                                            }
                                            .disabled(selectedDate == date && selectedMap == map)
                                        }
                                    }
                                }
                            } label: {
                                SquareButton {
                                    // Intentionally left blank
                                } label: {
                                    Image(systemName: "building")
                                        .font(.title2)
                                }
                            }
                        }
                        .offset(x: -12.0, y: -12.0)
                        Color.clear
                    }
                }
                #endif
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    Group {
                        #if !os(visionOS)
                        if orientation.isPortrait() || orientation.isOniPad() {
                            MapToolbar(selectedDate: $selectedDate, selectedMap: $selectedMap)
                        } else {
                            Color.clear
                                .frame(height: 0.0)
                        }
                        #else
                        MapToolbar(selectedDate: $selectedDate, selectedMap: $selectedMap)
                        #endif
                    }
                }
            }
            .onAppear {
                if !isInitialLoadCompleted {
                    selectedDate = dates.first(where: {$0.id == selectedDateID})
                    selectedMap = maps.first(where: {$0.id == selectedMapID})
                    isInitialLoadCompleted = true
                }
            }
            .onChange(of: selectedDate) { _, _ in
                if isInitialLoadCompleted {
                    selectedDateID = selectedDate?.id ?? 0
                }
            }
            .onChange(of: selectedMap) { _, _ in
                if isInitialLoadCompleted {
                    selectedMapID = selectedMap?.id ?? 0
                }
            }
            .onChange(of: isDatabaseInitialized) { _, newValue in
                if !newValue {
                    selectedMap = nil
                    selectedDate = nil
                }
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                        .automaticNavigationTransition(
                            id: "Layout.\(circle.blockID).\(circle.spaceNumber)",
                            in: mapNamespace
                        )
                default: Color.clear
                }
            }
        }
    }
}
