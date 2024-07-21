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
        List {
            Section {
                ForEach(databaseManager.events, id: \.self) { event in
                    VStack(alignment: .leading) {
                        Text(event.name)
                        Divider()
                        let eventDates = databaseManager.eventDates.filter({ $0.number == event.number })
                        HStack {
                            if eventDates.count > 0 {
                                ForEach(eventDates, id: \.self) { eventDate in
                                    Text(eventDate.date, style: .date)
                                    Divider()
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                ForEach(databaseManager.eventMaps, id: \.self) { eventMap in
                    Text(eventMap.filename)
                }
            }
        }
        .task {
            if let token = authManager.token {
                await eventManager.getEvents(authToken: token)
                if let placeholderEvent = eventManager.events.first {
                    // TODO: Load all events instead of .first
                    await databaseManager.downloadDatabases(for: placeholderEvent, authToken: token)
                    databaseManager.loadDatabase()
                    databaseManager.loadEvents()
                    databaseManager.loadDates()
                    databaseManager.loadMaps()
                }
            }
        }
    }
}
