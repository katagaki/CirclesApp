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
    @Environment(DatabaseManager.self) var database

    var body: some View {
        List {
            Section {
                Button("More.DBAdmin.DeleteDBs", role: .destructive) {
                    database.deleteDatabases()
                }
            }
            Section {
                ForEach(database.events, id: \.self) { event in
                    VStack(alignment: .leading) {
                        Text(event.name)
                        Divider()
                        let eventDates = database.eventDates.filter({ $0.eventNumber == event.eventNumber })
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
                ForEach(database.eventMaps, id: \.self) { eventMap in
                    Text(eventMap.filename)
                }
            } header: {
                ListSectionHeader(text: "Shared.Maps")
                    .font(.body)
            }
            Section {
                ForEach(database.eventAreas, id: \.self) { eventArea in
                    Text(eventArea.name)
                }
            } header: {
                ListSectionHeader(text: "Shared.Areas")
                    .font(.body)
            }
            Section {
                ForEach(database.eventBlocks, id: \.self) { eventBlock in
                    Text(eventBlock.name)
                }
            } header: {
                ListSectionHeader(text: "Shared.Blocks")
                    .font(.body)
            }
            Section {
                ForEach(database.eventGenres, id: \.self) { eventGenre in
                    Text(eventGenre.name)
                }
            } header: {
                ListSectionHeader(text: "Shared.Genres")
                    .font(.body)
            }
            Section {
                ForEach(database.eventLayouts, id: \.self) { eventLayout in
                    Text(verbatim: "\(eventLayout.blockID) | \(eventLayout.spaceNumber)")
                }
            } header: {
                ListSectionHeader(text: "Shared.Layouts")
                    .font(.body)
            }
            Section {
                ForEach(database.eventCircles, id: \.self) { eventCircle in
                    HStack {
                        if let image = database.circleImage(for: eventCircle.id) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32.0, height: 32.0)
                        }
                        VStack(alignment: .leading) {
                            Text(verbatim: "\(eventCircle.circleName) | \(eventCircle.penName)")
                            Text(verbatim: "\(eventCircle.blockID) | \(eventCircle.spaceNumber) | \(eventCircle.spaceNumberSuffix)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
                    await database.downloadDatabases(for: placeholderEvent, authToken: token)
                    database.loadDatabase()
                    database.loadEvents()
                    database.loadDates()
                    database.loadMaps()
                    database.loadAreas()
                    database.loadBlocks()
                    database.loadGenres()
                    database.loadLayouts()
                    database.loadCircles()
                    database.loadCircleExtendedInformtion()
                    database.loadCommonImages()
                    database.loadCircleImages()
                    debugPrint("Database loaded")
                }
            }
        }
    }
}
