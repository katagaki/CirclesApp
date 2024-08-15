//
//  MapView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import Komponents
import SwiftUI

struct MapView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(DatabaseManager.self) var database

    @State var selectedEventDate: ComiketDate?
    @State var selectedMap: ComiketMap?

    @State var isZoomedToFit: Bool = false

    // TODO: Put this in an environment state
    @State var isSelectingEvent: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.map]) {
            InteractiveMap(
                selectedEventDate: $selectedEventDate,
                selectedMap: $selectedMap,
                isZoomedToFit: $isZoomedToFit
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Shared.SelectEvent", systemImage: "calendar") {
                        isSelectingEvent = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Shared.ZoomToFit",
                           systemImage: (isZoomedToFit ?
                                         "arrow.down.backward.and.arrow.up.forward" :
                                            "arrow.up.forward.and.arrow.down.backward")) {
                        withAnimation(.snappy.speed(2.0)) {
                            isZoomedToFit.toggle()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12.0) {
                            ForEach(database.eventDates, id: \.id) { date in
                                VStack(alignment: .leading, spacing: 8.0) {
                                    Text("Shared.\(date.id)th.Day")
                                        .font(.title3)
                                        .bold()
                                    HStack(spacing: 8.0) {
                                        ForEach(database.eventMaps, id: \.id) { map in
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
                }
            }
            .sheet(isPresented: $isSelectingEvent) {
                EventSelector()
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
