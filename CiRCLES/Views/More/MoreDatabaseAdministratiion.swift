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

    @AppStorage(wrappedValue: false, "More.DBAdmin.SkipDownload") var willSkipDownload: Bool

    var body: some View {
        List {
            Section {
                Toggle("More.DBAdmin.SkipDownload", isOn: $willSkipDownload)
                Button("More.DBAdmin.RepairData", role: .destructive) {
                    withAnimation(.snappy.speed(2.0)) {
                        database.isBusy = true
                    } completion: {
                        UIApplication.shared.isIdleTimerDisabled = true
                        database.progressTextKey = ""
                        Task {
                            if !willSkipDownload {
                                if let token = authManager.token,
                                   let eventData = await WebCatalog.events(authToken: token),
                                   let latestEvent = eventData.list.first(where: {$0.id == eventData.latestEventID}) {
                                    database.delete()
                                    await MainActor.run {
                                        database.progressTextKey = "Shared.LoadingText.DownloadTextDatabase"
                                    }
                                    await database.downloadTextDatabase(for: latestEvent, authToken: token)
                                    await MainActor.run {
                                        database.progressTextKey = "Shared.LoadingText.DownloadImageDatabase"
                                    }
                                    await database.downloadImageDatabase(for: latestEvent, authToken: token)
                                }
                            }
                            if let textDatabaseURL = database.textDatabaseURL {
                                do {
                                    debugPrint("Opening text database")
                                    let textDatabase = try Connection(
                                        textDatabaseURL.path(percentEncoded: false),
                                        readonly: true
                                    )
                                    UIApplication.shared.isIdleTimerDisabled = true
                                    withAnimation(.snappy.speed(2.0)) {
                                        database.isBusy = true
                                        database.progressTextKey = "Shared.LoadingText.RepairingData"
                                    } completion: {
                                        Task {
                                            let actor = DataConverter(modelContainer: sharedModelContainer)
                                            await actor.deleteAllData()
                                            await actor.loadAll(from: textDatabase)
                                            await MainActor.run {
                                                withAnimation(.snappy.speed(2.0)) {
                                                    database.isBusy = false
                                                    UIApplication.shared.isIdleTimerDisabled = false
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    debugPrint(error.localizedDescription)
                                }
                            } else {
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
            }
        }
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
    }
}
