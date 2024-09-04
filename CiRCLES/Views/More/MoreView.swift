//
//  MoreView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Komponents
import SwiftData
import SwiftUI

// swiftlint:disable type_body_length
struct MoreView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(DatabaseManager.self) var database

    @Query(sort: [SortDescriptor(\ComiketEvent.eventNumber, order: .reverse)])
    var events: [ComiketEvent]

    @State var userInfo: UserInfo.Response?
    @State var userEvents: [UserCircle.Response.Circle] = []
    @State var eventData: WebCatalogEvent.Response?
    @State var eventDates: [Int: Date]?

    @AppStorage(wrappedValue: false, "Customization.ShowSpaceName") var showSpaceName: Bool
    @AppStorage(wrappedValue: false, "Customization.ShowDay") var showDay: Bool

    @State var isShowingUserPID: Bool = false

    var body: some View {
        NavigationStack(path: $navigationManager[.more]) {
            MoreList(repoName: "katagaki/CirclesApp", viewPath: ViewPath.moreAttributions) {
                Section {
                    HStack(alignment: .center, spacing: 16.0) {
                        Image(.profile1)
                            .resizable()
                            .frame(width: 56.0, height: 56.0)
                            .clipShape(.circle)
                        VStack(alignment: .leading) {
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
                        Spacer()
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        isShowingUserPID.toggle()
                    }
                    Link(destination: URL(string: "https://myportal.circle.ms/")!) {
                        HStack(alignment: .center) {
                            Text("Profile.Edit")
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Shared.Logout", role: .destructive) {
                        authManager.resetAuthentication()
                    }
                    .contextMenu {
                        Button("Shared.LoginAgain", role: .destructive) {
                            authManager.isAuthenticating = true
                        }
                    }
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
                Section {
                    Group {
                        switch Locale.current.language.languageCode {
                        case .japanese:
                            Link(destination: URL(string: "https://www.bigsight.jp/visitor/floormap/")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.BigSight", title: "More.UsefulResources.BigSightMap")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                            Link(destination: URL(string: "https://webcatalog.circle.ms")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.WebCatalog", title: "More.UsefulResources.WebCatalog")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                        default:
                            Link(destination: URL(string: "https://www.bigsight.jp/english/visitor/floormap/")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.BigSight", title: "More.UsefulResources.BigSightMap")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                            Link(destination: URL(string: "https://int.webcatalog.circle.ms/en/catalog")!) {
                                HStack(alignment: .center) {
                                    ListRow(image: "ListIcon.WebCatalog", title: "More.UsefulResources.WebCatalog")
                                        .foregroundStyle(.foreground)
                                    Spacer()
                                    Image(systemName: "safari")
                                        .foregroundStyle(.foreground.opacity(0.5))
                                }
                            }
                        }
                    }
                } header: {
                    ListSectionHeader(text: "More.UsefulResources")
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
                        ListSectionHeader(text: "More.Events")
                    }
                }
                Section {
                    Toggle("More.Customization.ShowHallAndBlock", isOn: $showSpaceName)
                    Toggle("More.Customization.ShowDay", isOn: $showDay)
                } header: {
                    ListSectionHeader(text: "More.Customization")
                }
                Section {
                    NavigationLink(value: ViewPath.moreDBAdmin) {
                        ListRow(image: "ListIcon.MasterDB", title: "More.DBAdmin.ManageDB")
                    }
                } header: {
                    ListSectionHeader(text: "More.DBAdmin")
                } footer: {
                    VStack(alignment: .leading, spacing: 20.0) {
                        Text("More.ProvidedBy")
                        Text("More.Disclaimer")
                    }
                    .font(.body)
                    .padding([.top], 20.0)
                }
            }
            .onAppear {
                reloadInformation()
            }
            .onChange(of: authManager.token) { _, _ in
                reloadInformation()
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .moreDBAdmin: MoreDatabaseAdministratiion()
                case .moreAttributions:
                    LicensesView(licenses: [
                        License(libraryName: "KeychainAccess", text: """
The MIT License (MIT)

Copyright (c) 2014 kishikawa katsumi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


"""),
                        License(libraryName: "SQlite.swift", text: """
(The MIT License)

Copyright (c) 2014-2015 Stephen Celis (<stephen@stephencelis.com>)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""),
                        License(libraryName: "ZIPFoundation", text: """
MIT License

Copyright (c) 2017-2024 Thomas Zoechling (https://www.peakstep.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

""")
                    ])
                default: Color.clear
                }
            }
        }
    }

    func reloadInformation() {
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
// swiftlint:enable type_body_length
