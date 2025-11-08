//
//  MoreView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftData
import SwiftUI

struct MoreView: View {
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    var body: some View {
        MoreList(repoName: "katagaki/CirclesApp", viewPath: UnifiedPath.moreAttributions) {
            Section {
                NavigationLink(value: UnifiedPath.moreDBAdmin) {
                    ListRow(image: "ListIcon.MasterDB", title: "More.DBAdmin.ManageDB")
                }
            } header: {
                Text("More.DBAdmin")
            } footer: {
                Text("More.ProvidedBy")
            }
            Section {
                Text("More.Disclaimer")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 20.0)
                .listRowBackground(Color.clear)
            }
        }
        .listSectionSpacing(.compact)
    }
}
