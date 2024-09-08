//
//  MyEventPickerSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct MyEventPickerSection: View {

    @Environment(AuthManager.self) var authManager

    var eventData: WebCatalogEvent.Response

    @AppStorage(wrappedValue: -1, "Events.Active.Number") var activeEventNumber: Int
    @AppStorage(wrappedValue: true, "Events.Active.IsLatest") var isActiveEventLatest: Bool

    var body: some View {
        Section {
            Picker(selection: $activeEventNumber) {
                ForEach(eventData.list.sorted(by: {$0.number > $1.number}), id: \.id) { event in
                    Text("Shared.Event.\(event.number)")
                        .tag(event.number)
                }
            } label: {
                Text("My.Events.SelectEvent")
            }
            .pickerStyle(.menu)
            .disabled(authManager.onlineState == .offline ||
                      authManager.onlineState == .undetermined)
        } header: {
            ListSectionHeader(text: "My.Events")
        } footer: {
            Text("My.Events.Disclaimer")
                .font(.body)
        }
        .onChange(of: activeEventNumber) { _, newValue in
            isActiveEventLatest = newValue == eventData.latestEventNumber
        }
    }
}
