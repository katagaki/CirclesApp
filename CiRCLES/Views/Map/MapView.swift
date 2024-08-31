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

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(DatabaseManager.self) var database

    @State var orientation = UIDeviceOrientation.portrait

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @AppStorage(wrappedValue: 0, "Map.SelectedEventDateID") var selectedEventDateID: Int
    @AppStorage(wrappedValue: 0, "Map.SelectedMapID") var selectedMapID: Int

    @State var selectedEventDate: ComiketDate?
    @State var selectedMap: ComiketMap?

    @State var isSettingsRestored: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.map]) {
            InteractiveMap(
                date: $selectedEventDate,
                map: $selectedMap
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ViewTitle.Map")
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2.0) {
                        if let selectedEventDate, let selectedMap {
                            Text(selectedMap.name)
                                .bold()
                            Text("Shared.\(selectedEventDate.id)th.Day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    Group {
                        if orientation.isPortrait || UIDevice.current.userInterfaceIdiom == .pad {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12.0) {
                                    ForEach(dates, id: \.id) { date in
                                        VStack(alignment: .leading, spacing: 12.0) {
                                            Text("Shared.\(date.id)th.Day")
                                                .font(.title3)
                                                .bold()
                                            Divider()
                                            HStack(spacing: 8.0) {
                                                ForEach(maps, id: \.id) { map in
                                                    BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                                       accentColor: accentColorForMap(map),
                                                                       isTextLight: true) {
                                                        withAnimation(.snappy.speed(2.0)) {
                                                            selectedEventDate = date
                                                            selectedMap = map
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(12.0)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12.0)
                                                .stroke(Color.primary.opacity(0.1))
                                        }
                                    }
                                }
                                .padding([.leading, .trailing], 12.0)
                                .padding([.top, .bottom], 12.0)
                            }
                            .scrollIndicators(.hidden)
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
                if !isSettingsRestored {
                    debugPrint("Restoring Maps view state")
                    selectedEventDate = dates.first(where: {$0.id == selectedEventDateID})
                    selectedMap = maps.first(where: {$0.id == selectedMapID})
                    isSettingsRestored = true
                }
            }
            .onChange(of: selectedEventDate) { _, _ in
                selectedEventDateID = selectedEventDate?.id ?? 0
            }
            .onChange(of: selectedMap) { _, _ in
                selectedMapID = selectedMap?.id ?? 0
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                default: Color.clear
                }
            }
        }
    }

    func accentColorForMap(_ map: ComiketMap) -> Color? {
        if map.name.starts(with: "東") {
            return Color.red
        } else if map.name.starts(with: "西") {
            return Color.blue
        } else if map.name.starts(with: "南") {
            return Color.green
        } else if map.name.starts(with: "会議") || map.name.starts(with: "会") {
            return Color.gray
        } else {
            return nil
        }
    }
}
