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
    @Environment(DatabaseManager.self) var database

    var body: some View {
        List {
            Section {
                Button("More.DBAdmin.RedownloadDBs", role: .destructive) {
                    if let token = authManager.token {
                        withAnimation(.snappy.speed(2.0)) {
                            database.isBusy = true
                        } completion: {
                            UIApplication.shared.isIdleTimerDisabled = true
                            Task.detached {
                                if let eventData = await WebCatalog.events(authToken: token),
                                   let latestEvent = eventData.list.first(where: {$0.id == eventData.latestEventID}) {
                                    await database.delete()
                                    await database.download(for: latestEvent, authToken: token)
                                }
                                await MainActor.run {
                                    withAnimation(.snappy.speed(2.0)) {
                                        database.isBusy = false
                                        UIApplication.shared.isIdleTimerDisabled = false
                                    }
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
                                var actor = DataConverter(modelContainer: sharedModelContainer)
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
