//
//  ChecklistsView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

struct ChecklistsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(ChecklistsManager.self) var checklists
    @Environment(DatabaseManager.self) var database

    var body: some View {
        NavigationStack(path: $navigationManager[.checklists]) {
            List(checklists.checklists, id: \.circle.webCatalogID) { checklist in
                Text(checklist.circle.name)
            }
        }
        .task {
            if let token = authManager.token {
                await checklists.getChecklists(authToken: token)
            }
        }
    }
}
