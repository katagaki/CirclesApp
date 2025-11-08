//
//  MyView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/06.
//

import SwiftData
import SwiftUI

struct MyView: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Events.self) var planner

    @Query var events: [ComiketEvent]

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

    var body: some View {
        HStack {
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    List {
                        if isInitialLoadCompleted {
                            MyProfileSection(userInfo: $userInfo)
                        }
                    }
                }
                List {
                    if isInitialLoadCompleted {
                        if UIDevice.current.userInterfaceIdiom != .pad {
                            MyProfileSection(userInfo: $userInfo)
                        }
                        MyParticipationSections(
                            eventTitle: $eventTitle,
                            eventDates: $eventDates,
                            dateForNotifier: $dateForNotifier,
                            dayForNotifier: $dayForNotifier,
                            participationForNotifier: $participationForNotifier
                        )
                    }
                }
                .contentMargins(.top, 0.0)
            }
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
        }
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
        .onAppear {
            if !isInitialLoadCompleted {
                reloadDataInBackground()
            }
        }
    }

    func reloadDataInBackground(forceReload: Bool = false) {
        if let token = authenticator.token,
           forceReload || userInfo == nil || userEvents.isEmpty || eventData == nil || eventDates == nil {
            Task.detached {
                await reloadData(using: token)
                await MainActor.run {
                     withAnimation(.smooth.speed(2.0)) {
                         eventTitle = events.first(where: {
                             $0.eventNumber == planner.activeEventNumber
                         })?.name
                         isInitialLoadCompleted = true
                     }
                }
            }
        } else if authenticator.onlineState == .offline {
            isInitialLoadCompleted = true
        }
    }

    func reloadData(using token: OpenIDToken) async {
        let userInfo = await User.info(authToken: token)
        let userEvents = await User.events(authToken: token)

        var eventDates: [Int: Date]?

        if let eventNumber = planner.activeEvent?.number {
            let actor = DataFetcher(modelContainer: sharedModelContainer)
            eventDates = await actor.dates(for: eventNumber)
        }

        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.userInfo = userInfo
                self.userEvents = userEvents
                self.eventData = eventData
                self.eventDates = eventDates
                self.eventCoverImage = database.coverImage()
            }
        }
    }
}
