//
//  MoreDatabase.swift
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
    @Environment(Database.self) var database
    @Environment(Oasis.self) var oasis

    @AppStorage(wrappedValue: false, "More.DBAdmin.SkipDownload") var willSkipDownload: Bool

    var body: some View {
        List {
            Section {
                Toggle("More.DBAdmin.SkipDownload", isOn: $willSkipDownload)
                Button("More.DBAdmin.RepairData", role: .destructive) {
                    oasis.open {
                        Task {
                            await repairData()
                        }
                    }
                }
            }
        }
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
    }

    func repairData() async {
        UIApplication.shared.isIdleTimerDisabled = true
        oasis.open()
        if !willSkipDownload {
            if let token = authManager.token,
               let eventData = await WebCatalog.events(authToken: token),
               let latestEvent = eventData.list.first(where: {$0.id == eventData.latestEventID}) {
                database.delete()
                await oasis.setBodyText("Shared.LoadingText.DownloadTextDatabase")
                await database.downloadTextDatabase(for: latestEvent, authToken: token) { progress in
                    await oasis.setProgress(progress)
                }
                await oasis.setBodyText("Shared.LoadingText.DownloadImageDatabase")
                await database.downloadImageDatabase(for: latestEvent, authToken: token) { progress in
                    await oasis.setProgress(progress)
                }
            }
        }
        if let textDatabaseURL = database.textDatabaseURL {
            do {
                let textDatabase = try Connection(
                    textDatabaseURL.path(percentEncoded: false),
                    readonly: true
                )
                await oasis.setBodyText("Shared.LoadingText.RepairingData")
                let actor = DataConverter(modelContainer: sharedModelContainer)
                await actor.deleteAll()
                await actor.loadAll(from: textDatabase)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        oasis.close()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
