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

    @State var selectedEventDate: Int?
    @State var selectedHall: ComiketHall?
    @State var selectedHallName: String?

    @State var isZoomedToFit: Bool = false

    // TODO: Put this in an environment state
    @State var isSelectingEvent: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.map]) {
            InteractiveMap(
                selectedEventDate: $selectedEventDate,
                selectedHall: $selectedHall,
                isZoomedToFit: $isZoomedToFit
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("ViewTitle.Map")
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2.0) {
                        if let selectedEventDate, let selectedHallName {
                            Text("Shared.\(selectedEventDate)th.Day")
                                .bold()
                            Text(selectedHallName)
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
                        HStack(spacing: 8.0) {
                            ForEach(database.eventDates, id: \.id) { date in
                                VStack(alignment: .leading, spacing: 6.0) {
                                    Text("Shared.\(date.id)th.Day")
                                        .bold()
                                    HStack(spacing: 8.0) {
                                        ForEach(database.eventMaps, id: \.id) { map in
                                            if selectedEventDate == date.id && selectedHall?.rawValue == map.filename {
                                                BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                                   isTextLight: true) { }
                                            } else {
                                                BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                                   isSecondary: true) {
                                                    withAnimation(.snappy.speed(2.0)) {
                                                        selectedEventDate = date.id
                                                        selectedHall = ComiketHall(rawValue: map.filename)
                                                        selectedHallName = map.name
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.leading, .trailing], 16.0)
                        .padding([.top, .bottom], 12.0)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .sheet(isPresented: $isSelectingEvent) {
                EventSelector()
            }
        }
    }
}
