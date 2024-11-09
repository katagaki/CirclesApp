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

    @AppStorage(wrappedValue: -1, "Events.Active.Number") var activeEventNumber: Int

    @State var isInitialLoadCompleted: Bool = false

    var body: some View {
        NavigationStack(path: $navigator[.map]) {
            InteractiveMap(
                date: $selectedDate,
                map: $selectedMap
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ViewTitle.Map")
            .toolbarBackground(UIDevice.current.userInterfaceIdiom == .pad ? .hidden : .visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2.0) {
                            if let selectedDate, let selectedMap {
                                Text(selectedMap.name)
                                    .bold()
                                Text("Shared.\(selectedDate.id)th.Day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
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
            .onChange(of: activeEventNumber) { oldValue, _ in
                if oldValue != -1 {
                    selectedMap = nil
                    selectedDate = nil
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
