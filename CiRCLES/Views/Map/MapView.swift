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

    @EnvironmentObject var navigator: Navigator
    @Environment(Database.self) var database

    @State var orientation = UIDeviceOrientation.portrait

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
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ViewTitle.Map")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    ToolbarItem(placement: .principal) {
                        Color.clear
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    Group {
                        if orientation.isPortrait || UIDevice.current.userInterfaceIdiom == .pad {
                            MapSelector(selectedDate: $selectedDate, selectedMap: $selectedMap)
                        } else {
                            Color.clear
                                .frame(height: 0.0)
                        }
                    }
                    .onRotate { newOrientation in
                        orientation = newOrientation
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
