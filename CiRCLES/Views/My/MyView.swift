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

    @EnvironmentObject var navigator: Navigator
    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Planner.self) var planner

    @Environment(\.colorScheme) private var colorScheme

    @Query var events: [ComiketEvent]

    @State var userInfo: UserInfo.Response?
    @State var userEvents: [UserCircle.Response.Circle] = []

    @State var eventData: WebCatalogEvent.Response?
    @State var eventDates: [Int: Date]?
    @State var eventCoverImage: UIImage?
    @State var eventTitle: String?

    @State var isShowingEventCoverImage: Bool = false
    @State var isGoingToSignOut: Bool = false

    @State var dateForNotifier: Date?
    @State var dayForNotifier: Int?
    @State var participationForNotifier: String?

    @State var isInitialLoadCompleted: Bool = false
    @State var isDeletingAccount: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    var body: some View {
        NavigationStack(path: $navigator[.my]) {
            HStack {
                Group {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        List {
                            if isInitialLoadCompleted {
                                MyProfileSection(userInfo: $userInfo)
                            }
                            Section {
                                Button("Shared.Logout") {
                                    isGoingToSignOut = true
                                }
                                .contextMenu {
                                    Button("Shared.LoginAgain", role: .destructive) {
                                        authenticator.isAuthenticating = true
                                    }
                                }
                            }
                            Section {
                                Button("More.DeleteAccount", role: .destructive) {
                                    #if !os(visionOS)
                                    isDeletingAccount = true
                                    #else
                                    openURL(URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                                    #endif
                                }
                            }
                        }
                    }
                    List {
                        if isInitialLoadCompleted {
                            if UIDevice.current.userInterfaceIdiom != .pad {
                                MyProfileSection(userInfo: $userInfo)
                            }
                            MyParticipationSections(
                                eventDates: $eventDates,
                                dateForNotifier: $dateForNotifier,
                                dayForNotifier: $dayForNotifier,
                                participationForNotifier: $participationForNotifier
                            )
                            MyEventPickerSection()
                        }
                        if UIDevice.current.userInterfaceIdiom != .pad {
                            Section {
                                Button("Shared.Logout") {
                                    isGoingToSignOut = true
                                }
                                .contextMenu {
                                    Button("Shared.LoginAgain", role: .destructive) {
                                        authenticator.isAuthenticating = true
                                    }
                                }
                            }
                            Section {
                                Button("More.DeleteAccount", role: .destructive) {
                                    #if !os(visionOS)
                                    isDeletingAccount = true
                                    #else
                                    openURL(URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                                    #endif
                                }
                            }
                        }
                    }
                }
                .listSectionSpacing(.compact)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("ViewTitle.My")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .pad {
                    ToolbarItem(placement: .principal) {
                        VStack(alignment: .center) {
                            Text(eventTitle ?? String(localized: "ViewTitle.My"))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.smooth.speed(2.0)) {
                                isShowingEventCoverImage.toggle()
                            }
                        }
                    }
                }
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
                                    .blur(radius: 10.0)
                            }
                    } else {
                        Color(uiColor: .systemGroupedBackground)
                    }
                }
                .animation(.smooth.speed(2.0), value: eventCoverImage)
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                BarAccessory(placement: .top) {
                    EventCoverImageAccessory(
                        isShowing: $isShowingEventCoverImage,
                        image: $eventCoverImage
                    )
                }
            }
            #if !os(visionOS)
            .sheet(isPresented: $isDeletingAccount) {
                SafariView(url: URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                    .ignoresSafeArea()
            }
            #endif
            .sheet(item: $dateForNotifier) { date in
                MyEventNotifierSheet(
                    date: date,
                    day: $dayForNotifier,
                    participation: $participationForNotifier
                )
            }
            .alert("Alerts.Logout.Title", isPresented: $isGoingToSignOut) {
                Button("Shared.Logout", role: .destructive) {
                    logout()
                }
                Button("Shared.Cancel", role: .cancel) {
                    isGoingToSignOut = false
                }
            } message: {
                Text("Alerts.Logout.Message")
            }
            .onAppear {
                if !isInitialLoadCompleted {
                    reloadDataInBackground()
                }
            }
            .onChange(of: authenticator.token) { _, _ in
                userInfo = nil
                reloadDataInBackground()
            }
            .onChange(of: authenticator.onlineState) { _, _ in
                reloadDataInBackground()
            }
            .onChange(of: isDatabaseInitialized) { _, newValue in
                if newValue {
                    reloadDataInBackground(forceReload: true)
                }
            }
            .onChange(of: database.commonImages) { _, _ in
                // TODO: Improve race condition when My tab is the startup tab
                if eventDates == nil {
                    reloadDataInBackground()
                }
                withAnimation(.snappy.speed(2.0)) {
                    eventCoverImage = database.coverImage()
                }
            }
        }
    }

    func reloadDataInBackground(forceReload: Bool = false) {
        if let token = authenticator.token,
           forceReload || userInfo == nil || userEvents.isEmpty || eventData == nil || eventDates == nil {
            Task.detached {
                await reloadData(using: token)
                await MainActor.run {
                     withAnimation(.snappy.speed(2.0)) {
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
            withAnimation(.snappy.speed(2.0)) {
                self.userInfo = userInfo
                self.userEvents = userEvents
                self.eventData = eventData
                self.eventDates = eventDates
                self.eventCoverImage = database.coverImage()
            }
        }
    }

    func logout() {
        database.delete()
        imageCache.clear()
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        Task.detached {
            let actor = DataConverter(modelContainer: sharedModelContainer)
            await actor.deleteAll()
            await MainActor.run {
                navigator.popToRoot(for: .map)
                navigator.popToRoot(for: .circles)
                navigator.popToRoot(for: .more)
                navigator.selectedTab = .map
                authenticator.resetAuthentication()
            }
        }
    }
}
