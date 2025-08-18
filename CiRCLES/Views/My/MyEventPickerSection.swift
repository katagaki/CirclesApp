//
//  MyEventPickerSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct MyEventPickerSection: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Events.self) var planner

    @State var activeEventNumber: Int = -1

    var body: some View {
        Section {
            if let eventData = planner.eventData {
                Picker(selection: $activeEventNumber) {
                    ForEach(eventData.list.sorted(by: {$0.number > $1.number}), id: \.id) { event in
                        Text("Shared.Event.\(event.number)")
                            .tag(event.number)
                    }
                } label: {
                    Text("My.Events.SelectEvent")
                }
                .pickerStyle(.menu)
                .disabled(authenticator.onlineState == .offline ||
                          authenticator.onlineState == .undetermined)
            } else {
                Text("My.Events.OfflineMode")
                    .foregroundStyle(.secondary)
            }
        } header: {
            ListSectionHeader(text: "My.Events")
        } footer: {
            Text("My.Events.Disclaimer")
                .font(.body)
        }
        .onAppear {
            activeEventNumber = planner.activeEventNumber
        }
        .onChange(of: activeEventNumber) { oldValue, _ in
            if oldValue != -1 {
                planner.activeEventNumber = activeEventNumber
            }
        }
    }
}
