//
//  MyView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/06.
//

import SwiftData
import SwiftUI
import RADiUS
import AXiS

struct MyView: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Events.self) var planner

    @State var events: [ComiketEvent] = []

    @State var userInfo: UserInfo.Response?
    @State var userEvents: [UserCircle.Response.Circle] = []

    @State var eventData: WebCatalogEvent.Response?
    @State var eventDates: [Int: Date]?
    @State var eventCoverImage: UIImage?
    @State var eventTitle: String?

    @State var isShowingEventCoverImage: Bool = false

    @State var dateForNotifier: Date?
    @State var dayForNotifier: Int?
    @State var participationForNotifier: String?

    @State var isInitialLoadCompleted: Bool = false
    @State var isDeletingAccount: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool
    @AppStorage("My.LastKnownNickname") var lastKnownNickname: String?
    @AppStorage(wrappedValue: 0, "My.LastKnownPID") var lastKnownPID: Int

    var body: some View {
        List {
            if isInitialLoadCompleted {
                MyProfileSection(userInfo: $userInfo)
                MyParticipationSections(
                    eventTitle: $eventTitle,
                    eventDates: $eventDates,
                    dateForNotifier: $dateForNotifier,
                    dayForNotifier: $dayForNotifier,
                    participationForNotifier: $participationForNotifier
                )
            }
        }
        .refreshable {
            await refreshUserInfo()
        }
        .contentMargins(.top, 0.0)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .navigationTitle(eventTitle ?? String(localized: "ViewTitle.My"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            MyToolbar(
                eventTitle: $eventTitle,
                eventCoverImage: $eventCoverImage,
                isShowingEventCoverImage: $isShowingEventCoverImage
            )
        }
        .background {
            Group {
                if let eventCoverImage {
                    Color(uiColor: eventCoverImage.accentColor)
                        .opacity(0.2)
                        .overlay {
                            Image(uiImage: eventCoverImage)
                                .ignoresSafeArea()
                                .scaledToFill()
                                .opacity(0.1)
                                .blur(radius: 5.0)
                        }
                } else {
                    Color(uiColor: .systemGroupedBackground)
                }
            }
            .animation(.smooth.speed(2.0), value: eventCoverImage)
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top, spacing: 0.0) {
            EventCoverImageAccessory(
                isShowing: $isShowingEventCoverImage,
                image: $eventCoverImage
            )
        }
        .sheet(item: $dateForNotifier) { date in
            MyEventNotifierSheet(
                date: date,
                day: $dayForNotifier,
                participation: $participationForNotifier
            )
        }
        .task {
            if !isInitialLoadCompleted {
                reloadDataInBackground()
            }
        }
        .onChange(of: authenticator.token?.accessToken) { _, _ in
            if userInfo == nil {
                reloadDataInBackground()
            }
        }
        .onChange(of: authenticator.effectiveOnlineState) { _, _ in
            if userInfo == nil {
                reloadDataInBackground()
            }
        }
    }

    func reloadDataInBackground(forceReload: Bool = false) {
        if authenticator.effectiveOnlineState == .offline {
            isInitialLoadCompleted = true
            return
        }
        if let token = authenticator.token, !token.accessToken.isEmpty,
           forceReload || userInfo == nil || userEvents.isEmpty || eventData == nil || eventDates == nil {
            Task.detached {
                await reloadData(using: token)
                await MainActor.run {
                     withAnimation(.smooth.speed(2.0)) {
                         events = database.events()
                         eventTitle = events.first(where: {
                             $0.eventNumber == planner.activeEventNumber
                         })?.name
                         isInitialLoadCompleted = true
                     }
                }

            }
        }
    }

    func refreshUserInfo() async {
        guard let token = authenticator.token, !token.accessToken.isEmpty else { return }
        let userInfo = await User.info(authToken: token)
        await MainActor.run {
            if let userInfo {
                lastKnownNickname = userInfo.nickname
                lastKnownPID = userInfo.pid
                withAnimation(.smooth.speed(2.0)) {
                    self.userInfo = userInfo
                }
            }
        }
    }

    func reloadData(using token: OpenIDToken) async {
        let userInfo = await User.info(authToken: token)
        let userEvents = await User.events(authToken: token)

        var eventDates: [Int: Date]?

        if let eventNumber = planner.activeEvent?.number {
            let actor = DataFetcher(database: database.getTextDatabase())
            eventDates = await actor.dates(for: eventNumber)
        }

        await MainActor.run {
            if let userInfo {
                lastKnownNickname = userInfo.nickname
                lastKnownPID = userInfo.pid
            }
            withAnimation(.smooth.speed(2.0)) {
                if let userInfo {
                    self.userInfo = userInfo
                }
                self.userEvents = userEvents
                self.eventData = eventData
                self.eventDates = eventDates
                self.eventCoverImage = database.coverImage()
            }
        }
    }
}
