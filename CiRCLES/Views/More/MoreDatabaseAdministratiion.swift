//
//  MoreDatabaseManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftUI

struct MoreDatabaseAdministratiion: View {
    @Environment(AuthManager.self) var authManager
    @Environment(CatalogManager.self) var catalog
    @Environment(DatabaseManager.self) var database

    var body: some View {
        List {
            Section {
                Button("More.DBAdmin.DeleteDBs", role: .destructive) {
                    database.deleteAllData()
                }
                Button("More.DBAdmin.ReloadDBs", role: .destructive) {
                    withAnimation(.snappy.speed(2.0)) {
                        database.isBusy = true
                    }
                    Task {
                        if let token = authManager.token,
                           let latestEvent = catalog.latestEvent() {
                            await database.loadAll(forcefully: true)
                            database.isBusy = false
                        }
                    }
                }
            }
        }
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
    }
}
