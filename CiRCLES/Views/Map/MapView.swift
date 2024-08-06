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

    // TODO: Put this in an environment state
    @State var isSelectingEvent: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.map]) {
            ScrollView([.horizontal, .vertical]) {
                if let selectedEventDate, let selectedHall,
                   let mapImage = database.mapImage(for: selectedHall,
                                                    on: selectedEventDate,
                                                    usingHighDefinition: true) {
                    Image(uiImage: mapImage)
                        .ignoresSafeArea(.all)
                }
            }
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
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8.0) {
                            ForEach(database.eventDates, id: \.id) { date in
                                BarAccessoryButton("Shared.\(date.id)th.Day",
                                                   icon: "calendar",
                                                   isTextLight: true) {
                                    withAnimation(.snappy.speed(2.0)) {
                                        if selectedEventDate == date.id {
                                            selectedEventDate = nil
                                            selectedHall = nil
                                            selectedHallName = nil
                                        } else {
                                            selectedEventDate = date.id
                                        }
                                    }
                                }
                                if date.id == selectedEventDate {
                                    ForEach(database.eventMaps, id: \.id) { map in
                                        BarAccessoryButton(LocalizedStringKey(stringLiteral: map.name),
                                                           icon: "map",
                                                           isSecondary: true) {
                                            withAnimation(.snappy.speed(2.0)) {
                                                selectedHallName = map.name
                                                selectedHall = ComiketHall(rawValue: map.filename)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding([.leading, .trailing], 16.0)
                        .padding([.top, .bottom], 12.0)
                    }
                }
            }
            .sheet(isPresented: $isSelectingEvent) {
                EventSelector()
            }
        }
    }
}
