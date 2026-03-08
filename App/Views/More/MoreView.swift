//
//  MoreView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import SwiftData
import SwiftUI
import AXiS

struct MoreView: View {
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    var body: some View {
        List {
            Section {
                NavigationLink("More.DBAdmin.ManageDB", value: UnifiedPath.moreDBAdmin)
            } header: {
                Text("More.DBAdmin")
            } footer: {
                Text("More.ProvidedBy")
            }
            Section {
                Text("More.Disclaimer")
                .foregroundStyle(.secondary)
                .padding(.top, 20.0)
                .listRowBackground(Color.clear)
            }
            Section {
                Link(destination: URL(string: "https://github.com/katagaki/CirclesApp")!) {
                    HStack {
                        Text(String(localized: "More.GitHub"))
                        Spacer()
                        Text("katagaki/CirclesApp")
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
                NavigationLink("More.Attributions", value: UnifiedPath.moreAttributions)
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("ViewTitle.More")
        .navigationBarTitleDisplayMode(.inline)
    }
}
