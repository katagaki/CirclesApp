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
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
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
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    Group {
                        if orientation.isPortrait || UIDevice.current.userInterfaceIdiom == .pad {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12.0) {
                                    ForEach(dates, id: \.id) { date in
                                        VStack(alignment: .leading, spacing: 12.0) {
                                            HStack {
                                                Text("Shared.\(date.id)th.Day")
                                                    .bold()
                                                Spacer()
                                                Text(date.date, style: .date)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Divider()
                                            HStack(spacing: 8.0) {
                                                ForEach(maps, id: \.id) { map in
                                                    BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                                       accentColor: accentColorForMap(map),
                                                                       isTextLight: true) {
                                                        withAnimation(.snappy.speed(2.0)) {
                                                            selectedDate = date
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
                if !isInitialLoadCompleted {
                    debugPrint("Restoring Maps view state")
                    selectedDate = dates.first(where: {$0.id == selectedDateID})
                    selectedMap = maps.first(where: {$0.id == selectedMapID})
                    isInitialLoadCompleted = true
                }
            }
            .onChange(of: selectedDate) { _, _ in
                if isInitialLoadCompleted {
                    debugPrint("Updating selected date ID")
                    selectedDateID = selectedDate?.id ?? 0
                }
            }
            .onChange(of: selectedMap) { _, _ in
                if isInitialLoadCompleted {
                    debugPrint("Updating selected map ID")
                    selectedMapID = selectedMap?.id ?? 0
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
