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

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
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
            .navigationTitle("ViewTitle.Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                #if !os(visionOS)
                if orientation.isLandscape() ||
                    (horizontalSizeClass == .regular && verticalSizeClass == .compact) {
                    MapHallMenu(
                        selectedDate: $selectedDate,
                        selectedMap: $selectedMap
                    )
                    .transition(.push(from: .leading).animation(.smooth.speed(2.0)))
                }
                #endif
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                #if !os(visionOS)
                if orientation.isPortrait() ||
                    (horizontalSizeClass == .compact && verticalSizeClass == .regular) {
                    MapToolbar(selectedDate: $selectedDate, selectedMap: $selectedMap)
                        .frame(maxWidth: .infinity)
                } else {
                    Color.clear
                        .frame(height: 0.0)
                }
                #else
                MapToolbar(selectedDate: $selectedDate, selectedMap: $selectedMap)
                #endif
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
