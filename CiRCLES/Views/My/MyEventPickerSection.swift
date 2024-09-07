//
//  MyEventPickerSection.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

import Komponents
import SwiftUI

struct MyEventPickerSection: View {

    var eventData: WebCatalogEvent.Response

    var body: some View {
        Section {
            Picker(selection: .constant(eventData.latestEventID)) {
                ForEach(eventData.list.sorted(by: {$0.number > $1.number}), id: \.id) { event in
                    Text("Shared.Event.\(event.number)")
                        .tag(event.id)
                }
            } label: { }
                .pickerStyle(.inline)
        } header: {
            ListSectionHeader(text: "My.Events")
        }
    }
}
