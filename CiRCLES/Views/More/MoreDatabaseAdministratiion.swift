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
    @Environment(EventManager.self) var eventManager
    @Environment(DatabaseManager.self) var databaseManager

    var body: some View {
        List {
            Section {
                Button("More.DBAdmin.DeleteDBs", role: .destructive) {
                    databaseManager.deleteDatabases()
                }
            }
            Section {
                ForEach(databaseManager.events, id: \.self) { event in
                    VStack(alignment: .leading) {
                        Text(event.name)
                        Divider()
                        let eventDates = databaseManager.eventDates.filter({ $0.eventNumber == event.eventNumber })
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
            } header: {
                ListSectionHeader(text: "Shared.Events")
                    .font(.body)
            }
            Section {
                ForEach(databaseManager.eventMaps, id: \.self) { eventMap in
                    Text(eventMap.filename)
                }
            } header: {
                ListSectionHeader(text: "Shared.Maps")
                    .font(.body)
            }
            Section {
                ForEach(databaseManager.eventAreas, id: \.self) { eventArea in
                    Text(eventArea.name)
                }
            } header: {
                ListSectionHeader(text: "Shared.Areas")
                    .font(.body)
            }
            Section {
                ForEach(databaseManager.eventBlocks, id: \.self) { eventBlock in
                    Text(eventBlock.name)
                }
            } header: {
                ListSectionHeader(text: "Shared.Blocks")
                    .font(.body)
            }
            Section {
                ForEach(databaseManager.eventGenres, id: \.self) { eventGenre in
                    Text(eventGenre.name)
                }
            } header: {
                ListSectionHeader(text: "Shared.Genres")
                    .font(.body)
            }
            Section {
                ForEach(databaseManager.eventLayouts, id: \.self) { eventLayout in
                    Text(verbatim: "\(eventLayout.blockID) | \(eventLayout.spaceNumber)")
                }
            } header: {
                ListSectionHeader(text: "Shared.Layouts")
                    .font(.body)
            }
            Section {
                ForEach(databaseManager.eventCircles, id: \.self) { eventCircle in
                    VStack(alignment: .leading) {
                        Text(verbatim: "\(eventCircle.circleName) | \(eventCircle.penName)")
                        Divider()
                        Text(verbatim: "\(eventCircle.blockID) | \(eventCircle.spaceNumber) | \(eventCircle.spaceNumberSuffix)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                ListSectionHeader(text: "Shared.Circles")
                    .font(.body)
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
                    databaseManager.loadAreas()
                    databaseManager.loadBlocks()
                    databaseManager.loadGenres()
                    databaseManager.loadLayouts()
                    databaseManager.loadCircles()
                }
            }
        }
    }
}
