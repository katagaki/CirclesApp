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

    @Binding var eventData: WebCatalogEvent.Response?
    @Binding var activeEventNumber: Int

    var body: some View {
        Section {
            Picker(selection: $activeEventNumber) {
                if let eventData {
                    ForEach(eventData.list.sorted(by: {$0.number > $1.number}), id: \.id) { event in
                        Text("Shared.Event.\(event.number)")
                            .tag(event.number)
                    }
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
    }
}
