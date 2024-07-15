//
//  MoreDatabaseManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import SwiftUI

struct MoreDatabaseAdministratiion: View {
    @Environment(AuthManager.self) var authManager
    @Environment(EventManager.self) var eventManager
    @Environment(DatabaseManager.self) var databaseManager

    var body: some View {
        ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
            .task {
                if let token = authManager.token {
                    await eventManager.getEvents(authToken: token)
                    if let placeholderEvent = eventManager.events.first {
                        // TODO: Load all events instead of .first
                        await databaseManager.getDatabases(for: placeholderEvent, authToken: token)
                        await databaseManager.downloadDatabases()
                        databaseManager.getComiketMap()
                    }
                }
            }
    }
}
