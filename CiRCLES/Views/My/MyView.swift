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
    @Environment(AuthManager.self) var authManager
    @Environment(Database.self) var database

    @Environment(\.colorScheme) private var colorScheme

    @Query var events: [ComiketEvent]

    @State var userInfo: UserInfo.Response?
    @State var userEvents: [UserCircle.Response.Circle] = []

    @State var eventData: WebCatalogEvent.Response?
    @State var eventDates: [Int: Date]?
    @State var eventCoverImage: UIImage?

    @State var isShowingEventCoverImage: Bool = false
    @State var isGoingToSignOut: Bool = false

    @State var dateForNotifier: Date?
    @State var dayForNotifier: Int?
    @State var participationForNotifier: String?

    @State var isShowingDeleteAccountSafariViewController: Bool = false

    @AppStorage(wrappedValue: -1, "Events.Active.Number") var activeEventNumber: Int

    @AppStorage(wrappedValue: "", "My.Participation") var participation: String
    @State var participationState: [String: [String: String]] = [:]

    var body: some View {
        NavigationStack(path: $navigator[.my]) {
            HStack {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    List {
                        MyProfileSection(userInfo: $userInfo)
                        Section {
                            Button("Shared.Logout") {
                                isGoingToSignOut = true
                            }
                            .contextMenu {
                                Button("Shared.LoginAgain", role: .destructive) {
                                    authManager.isAuthenticating = true
                                }
                            }
                        }
                        Section {
                            Button("More.DeleteAccount", role: .destructive) {
                                isShowingDeleteAccountSafariViewController = true
                            }
                        }
                    }
                    .listSectionSpacing(.compact)
                    .scrollContentBackground(.hidden)
                }
                List {
                    if UIDevice.current.userInterfaceIdiom != .pad {
                        MyProfileSection(userInfo: $userInfo)
                    }
                    if let eventDates, eventDates.count > 0 {
                        MyParticipationSections(
                            eventDates: eventDates,
                            dateForNotifier: $dateForNotifier,
                            dayForNotifier: $dayForNotifier,
                            participationForNotifier: $participationForNotifier,
                            activeEventNumber: $activeEventNumber
                        )
                    }
                    if let eventData {
                        MyEventPickerSection(
                            eventData: eventData,
                            activeEventNumber: $activeEventNumber
                        )
                    }
                    if UIDevice.current.userInterfaceIdiom != .pad {
                        Section {
                            Button("Shared.Logout") {
                                isGoingToSignOut = true
                            }
                            .contextMenu {
                                Button("Shared.LoginAgain", role: .destructive) {
                                    authManager.isAuthenticating = true
                                }
                            }
                        }
                        Section {
                            Button("More.DeleteAccount", role: .destructive) {
                                isShowingDeleteAccountSafariViewController = true
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
                ToolbarItem(placement: .principal) {
                    VStack(alignment: .center) {
                        Text(events.first(where: {$0.eventNumber == activeEventNumber})?.name ??
                             String(localized: "ViewTitle.My"))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        withAnimation(.smooth.speed(2.0)) {
                            isShowingEventCoverImage.toggle()
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
                    VStack {
                        if isShowingEventCoverImage, let eventCoverImage {
                            Image(uiImage: eventCoverImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8.0)
                                        .stroke(Color.primary.opacity(0.5), lineWidth: 1/3)
                                }
                                .frame(maxWidth: .infinity, maxHeight: 300.0, alignment: .center)
                        }
                        Image(.arrow)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 10.0, alignment: .center)
                            .rotationEffect(isShowingEventCoverImage ? Angle.degrees(180.0) : Angle.degrees(0.0))
                    }
                    .padding(.bottom, 6.0)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.smooth.speed(2.0)) {
                            isShowingEventCoverImage.toggle()
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingDeleteAccountSafariViewController) {
                SafariView(url: URL(string: "https://auth2.circle.ms/Account/WithDraw1")!)
                    .ignoresSafeArea()
            }
            .alert("Alerts.Logout.Title", isPresented: $isGoingToSignOut) {
                Button("Shared.Logout", role: .destructive) {
                    database.delete()
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
                            authManager.resetAuthentication()
                        }
                    }
                }
                Button("Shared.Cancel", role: .cancel) {
                    isGoingToSignOut = false
                }
            } message: {
                Text("Alerts.Logout.Message")
            }
            .onAppear {
                if let token = authManager.token,
                   userInfo == nil || userEvents.isEmpty || eventData == nil || eventDates == nil {
                    Task.detached {
                        await reloadData(using: token)
                    }
                }
            }
            .refreshable {
                if let token = authManager.token {
                    await reloadData(using: token)
                }
            }
            .onChange(of: authManager.token) { _, _ in
                if let token = authManager.token {
                    Task.detached {
                        await reloadData(using: token)
                    }
                }
            }
            .onChange(of: database.commonImages) { _, _ in
                withAnimation(.snappy.speed(2.0)) {
                    eventCoverImage = database.coverImage()
                }
            }
            .onChange(of: events) { _, _ in
                if let token = authManager.token,
                   userInfo == nil || userEvents.isEmpty || eventData == nil || eventDates == nil {
                    Task.detached {
                        await reloadData(using: token)
                    }
                }
            }
            .onChange(of: activeEventNumber) { oldValue, _ in
                if oldValue != -1 {
                    if let token = authManager.token {
                        Task.detached {
                            await reloadData(using: token)
                        }
                    }
                }
            }
            .sheet(item: $dateForNotifier) { date in
                MyEventNotifierSheet(
                    date: date,
                    day: $dayForNotifier,
                    participation: $participationForNotifier
                )
            }
        }
    }

    func reloadData(using token: OpenIDToken) async {
        let userInfo = await User.info(authToken: token)
        let userEvents = await User.events(authToken: token)
        let eventData = await WebCatalog.events(authToken: token)

        var eventDates: [Int: Date]?
        var eventNumber: Int?
        if activeEventNumber == -1, let eventData {
            eventNumber = eventData.latestEventNumber
        } else {
            eventNumber = activeEventNumber
        }

        if let eventNumber {
            let actor = DataFetcher(modelContainer: sharedModelContainer)
            eventDates = await actor.dates(for: eventNumber)
            activeEventNumber = eventNumber
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
}
