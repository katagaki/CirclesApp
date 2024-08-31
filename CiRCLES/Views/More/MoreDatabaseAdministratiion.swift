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
    @Environment(CatalogManager.self) var catalog
    @Environment(DatabaseManager.self) var database

    var body: some View {
        List {
            Section {
                Button("More.DBAdmin.DeleteDBs", role: .destructive) {
                    database.deleteDatabases()
                }
                Button("More.DBAdmin.RedownloadDBs", role: .destructive) {
                    database.deleteDatabases()
                    withAnimation(.snappy.speed(2.0)) {
                        database.isBusy = true
                    }
                    Task {
                        if let token = authManager.token,
                           let latestEvent = catalog.latestEvent() {
                            await database.downloadDatabases(for: latestEvent, authToken: token)
                            await database.loadAll()
                            database.isBusy = false
                        }
                    }
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
            }
            Section {
                Text(String(database.eventMaps.count))
            } header: {
                ListSectionHeader(text: "Shared.Maps")
            }
            Section {
                Text(String(database.eventAreas.count))
            } header: {
                ListSectionHeader(text: "Shared.Areas")
            }
            Section {
                Text(String(database.eventBlocks.count))
            } header: {
                ListSectionHeader(text: "Shared.Blocks")
            }
            Section {
                Text(String(database.eventGenres.count))
            } header: {
                ListSectionHeader(text: "Shared.Genres")
            }
            Section {
                Text(String(database.eventLayouts.count))
            } header: {
                ListSectionHeader(text: "Shared.Layouts")
            }
            Section {
                Text(String(database.eventCircles.count))
            } header: {
                ListSectionHeader(text: "Shared.Circles")
            }
        }
    }
}
