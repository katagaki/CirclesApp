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
        List(databaseManager.maps, id: \.self) { map in
            Text(map.name)
        }
            .task {
                if let token = authManager.token {
                    await eventManager.getEvents(authToken: token)
                    if let placeholderEvent = eventManager.events.first {
                        // TODO: Load all events instead of .first
                        await databaseManager.downloadDatabases(for: placeholderEvent, authToken: token)
                        databaseManager.getComiketMap()
                    }
                }
            }
    }
}
