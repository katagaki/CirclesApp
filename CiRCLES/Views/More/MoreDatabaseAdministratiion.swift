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

    var body: some View {
        ContentUnavailableView("Shared.NotImplemented", systemImage: "questionmark.square.dashed")
            .task {
                if let token = authManager.token,
                   let placeholderEvent = eventManager.events.first {
                    // TODO: Load all events instead of .first
                    await eventManager.getDatabases(for: placeholderEvent, authToken: token)
                }
            }
    }
}
