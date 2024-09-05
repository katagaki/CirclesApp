//
//  MyView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/06.
//

import Komponents
import SwiftData
import SwiftUI

struct MyView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(DatabaseManager.self) var database

    @Query(sort: [SortDescriptor(\ComiketEvent.eventNumber, order: .reverse)])
    var events: [ComiketEvent]

    @State var eventData: WebCatalogEvent.Response?
    @State var eventDates: [Int: Date]?

    @State var userInfo: UserInfo.Response?
    @State var userEvents: [UserCircle.Response.Circle] = []

    @State var isShowingUserPID: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.my]) {
            List {
                Section {
                    VStack(alignment: .center, spacing: 16.0) {
                        Image(.profile1)
                            .resizable()
                            .frame(width: 72.0, height: 72.0)
                            .clipShape(.circle)
                        VStack(alignment: .center) {
                            if let userInfo {
                                Text(userInfo.nickname)
                                .fontWeight(.medium)
                                .font(.title3)
                            } else {
                                ProgressView()
                            }
                            if isShowingUserPID {
                                Text("PID " + String(userInfo?.pid ?? 0))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(.rect)
                    .onTapGesture {
                        isShowingUserPID.toggle()
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in
                        0.0
                    }
                    Link(destination: URL(string: "https://myportal.circle.ms/")!) {
                        HStack(alignment: .center) {
                            Text("Profile.Edit")
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    ListSectionHeader(text: "My.Account")
                }
                if let latestEvent = events.first, let eventDates {
                    Section {
                        if let coverImage = database.coverImage() {
                            Image(uiImage: coverImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: 250.0, alignment: .center)
                        }
                        if eventDates.count > 0 {
                            ForEach(Array(eventDates.keys).sorted(), id: \.self) { dayID in
                                HStack {
                                    Text("Shared.\(dayID)th.Day")
                                    Spacer()
                                    if let date = eventDates[dayID] {
                                        Text(date, style: .date)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        ListSectionHeader(text: latestEvent.name)
                    }
                }
                if let eventData {
                    Section {
                        Picker(selection: .constant(eventData.latestEventID)) {
                            ForEach(eventData.list.sorted(by: {$0.number > $1.number}), id: \.id) { event in
                                Text("Shared.Event.\(event.number)")
                                    .tag(event.id)
                            }
                        } label: { }
                            .pickerStyle(.inline)
                    } header: {
                        ListSectionHeader(text: "My.Events")
                    }
                }
            }
            .navigationTitle("ViewTitle.My")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Shared.Logout", role: .destructive) {
                        authManager.resetAuthentication()
                    }
                    .contextMenu {
                        Button("Shared.LoginAgain", role: .destructive) {
                            authManager.isAuthenticating = true
                        }
                    }
                }
            }
            .onAppear {
                reloadData()
            }
            .onChange(of: authManager.token) { _, _ in
                reloadData()
            }
        }
    }

    func reloadData() {
        if let token = authManager.token {
            Task.detached {
                let userInfo = await User.info(authToken: token)
                let userEvents = await User.events(authToken: token)
                let eventData = await WebCatalog.events(authToken: token)

                var eventDates: [Int: Date]?
                if let latestEventNumber = eventData?.latestEventNumber {
                    let actor = DataFetcher(modelContainer: sharedModelContainer)
                    eventDates = await actor.dates(for: latestEventNumber)
                }

                await MainActor.run {
                    withAnimation(.snappy.speed(2.0)) {
                        self.userInfo = userInfo
                        self.userEvents = userEvents
                        self.eventData = eventData
                        self.eventDates = eventDates
                    }
                }
            }
        }
    }
}
