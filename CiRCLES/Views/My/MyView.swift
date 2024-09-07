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

    @Query(sort: [SortDescriptor(\ComiketEvent.eventNumber, order: .reverse)])
    var events: [ComiketEvent]

    @State var userInfo: UserInfo.Response?
    @State var userEvents: [UserCircle.Response.Circle] = []

    @State var eventData: WebCatalogEvent.Response?
    @State var eventDates: [Int: Date]?
    @State var eventCoverImage: UIImage?

    @State var isInitialLoadCompleted: Bool = false
    @State var isShowingEventCoverImage: Bool = false

    @AppStorage(wrappedValue: "", "My.Participation") var participation: String

    @State var participationState: [String: [String: String]] = [:]

    var body: some View {
        NavigationStack(path: $navigator[.my]) {
            List {
                MyProfileSection(userInfo: $userInfo)
                if let latestEvent = events.first, let eventDates, eventDates.count > 0 {
                    MyParticipationSections(latestEvent: latestEvent, eventDates: eventDates)
                }
                if let eventData {
                    MyEventPickerSection(eventData: eventData)
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle(events.first?.name ?? NSLocalizedString("ViewTitle.My", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
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
                            }
                    } else {
                        Color(uiColor: .systemGroupedBackground)
                    }
                }
                .animation(.smooth.speed(2.0), value: eventCoverImage)
            }
            .scrollContentBackground(.hidden)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(events.first?.name ?? NSLocalizedString("ViewTitle.My", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .onTapGesture {
                            withAnimation(.smooth.speed(2.0)) {
                                isShowingEventCoverImage.toggle()
                            }
                        }
                }
                ToolbarItem(placement: .principal) {
                    Color.clear
                }
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
            .onAppear {
                if let token = authManager.token,
                   userInfo == nil || userEvents.isEmpty || eventData == nil || eventDates == nil {
                    Task.detached {
                        await reloadData(using: token)
                    }
                }
            }
            .onAppear {
                if !isInitialLoadCompleted {
                    debugPrint("Restoring My view state")
                    if let token = authManager.token {
                        Task.detached {
                            await reloadData(using: token)
                        }
                    }
                    isInitialLoadCompleted = true
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
            .onChange(of: database.commonImages) {_, _ in
                withAnimation(.snappy.speed(2.0)) {
                    eventCoverImage = database.coverImage()
                }
            }
        }
    }

    func reloadData(using token: OpenIDToken) async {
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
                self.eventCoverImage = database.coverImage()
            }
        }
    }
}
