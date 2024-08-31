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
                Button("More.DBAdmin.RedownloadDBs", role: .destructive) {
                    Task {
                        if let token = authManager.token,
                           let latestEvent = catalog.latestEvent() {
                            database.deleteDatabases()
                            await database.downloadDatabases(for: latestEvent, authToken: token)
                        }
                    }
                }
                Button("More.DBAdmin.RepairData", role: .destructive) {
                    withAnimation(.snappy.speed(2.0)) {
                        database.isBusy = true
                    }
                    database.deleteAllData()
                    database.loadAll(forcefully: true)
                    withAnimation(.snappy.speed(2.0)) {
                        database.isBusy = false
                    }
                }
            }
        }
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
    }
}
