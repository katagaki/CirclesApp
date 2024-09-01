//
//  MoreDatabaseManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SQLite
import SwiftUI

typealias View = SwiftUI.View

struct MoreDatabaseAdministratiion: View {

    @Environment(AuthManager.self) var authManager
    @Environment(CatalogManager.self) var catalog
    @Environment(DatabaseManager.self) var database

    var body: some View {
        List {
            Section {
                Button("More.DBAdmin.RedownloadDBs", role: .destructive) {
                    if let token = authManager.token,
                       let latestEvent = catalog.latestEvent() {
                        withAnimation(.snappy.speed(2.0)) {
                            database.isBusy = true
                        }
                        UIApplication.shared.isIdleTimerDisabled = true
                        Task.detached {
                            await database.deleteDatabases()
                            await database.downloadDatabases(for: latestEvent, authToken: token)
                            await MainActor.run {
                                withAnimation(.snappy.speed(2.0)) {
                                    database.isBusy = false
                                    UIApplication.shared.isIdleTimerDisabled = false
                                }
                            }
                        }
                    }
                }
                Button("More.DBAdmin.RepairData", role: .destructive) {
                    if let textDatabaseURL = database.textDatabaseURL {
                        do {
                            debugPrint("Opening text database")
                            let textDatabase = try Connection(
                                textDatabaseURL.path(percentEncoded: false),
                                readonly: true
                            )
                            UIApplication.shared.isIdleTimerDisabled = true
                            Task.detached {
                                await MainActor.run {
                                    withAnimation(.snappy.speed(2.0)) {
                                        database.isBusy = true
                                        database.progressTextKey = "Shared.LoadingText.RepairingData"
                                    }
                                }
                                var actor = DatabaseActor(modelContainer: sharedModelContainer)
                                await actor.deleteAllData()
                                await actor.loadAll(from: textDatabase)
                                await MainActor.run {
                                    withAnimation(.snappy.speed(2.0)) {
                                        database.isBusy = false
                                        UIApplication.shared.isIdleTimerDisabled = false
                                    }
                                }
                            }
                        } catch {
                            debugPrint(error.localizedDescription)
                        }
                    }
                }
            }
        }
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
    }
}
