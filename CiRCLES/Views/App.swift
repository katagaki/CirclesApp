//
//  App.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/06/18.
//

import BackgroundTasks
import Komponents
import SwiftUI
import SwiftData

@main
struct CirclesApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @StateObject var navigator = Navigator<TabType, ViewPath>()
    @State var authenticator = Authenticator()
    @State var favorites = Favorites()
    @State var database = Database()
    @State var imageCache = ImageCache()
    @State var planner = Planner()
    @State var oasis = Oasis()

    @State var hasAppLaunchedForTheFirstTime: Bool = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    if url.absoluteString == circleMsCancelURLSchema {
                        authenticator.isWaitingForAuthenticationCode = false
                    } else {
                        authenticator.getAuthenticationCode(from: url)
                    }
                }
                .overlay {
                    if authenticator.onlineState == .offline {
                        ZStack(alignment: .top) {
                            Color.clear
                            LinearGradient(colors: [.pink.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 24.0)
                                .frame(maxWidth: .infinity)
                                .ignoresSafeArea()
                                .transition(.move(edge: .top).animation(.smooth.speed(2.0)))
                        }
                    }
                }
                .progressAlert(
                    isModal: $oasis.isModal,
                    isShowing: $oasis.isShowing,
                    headerText: $oasis.headerText,
                    bodyText: $oasis.bodyText,
                    progress: $oasis.progress
                )
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(navigator)
        .environment(authenticator)
        .environment(favorites)
        .environment(database)
        .environment(imageCache)
        .environment(planner)
        .environment(oasis)
        .onChange(of: scenePhase) { _, newValue in
            if !hasAppLaunchedForTheFirstTime {
                hasAppLaunchedForTheFirstTime = true
            } else {
                switch newValue {
                case .active:
                    if authenticator.token != nil && authenticator.onlineState == .online {
                        // Require authentication when token expires
                        if authenticator.tokenExpiryDate < .now {
                            authenticator.isAuthenticating = true
                        // Refresh authentication token 1 hour before expiry
                        } else if authenticator.tokenExpiryDate.addingTimeInterval(-3600) < .now {
                            Task {
                                await authenticator.refreshAuthenticationToken()
                            }
                        }
                        // Do nothing in any other case
                    }
                case .background:
                    registerBackgroundRefreshTask()
                default: break
                }
            }
        }
        .onChange(of: authenticator.code) { _, newValue in
            if newValue != nil {
                Task {
                    await authenticator.getAuthenticationToken()
                }
            }
        }
        .onChange(of: planner.participation) { _, _ in
            planner.participationUserDefault = planner.participation
        }
        .onChange(of: navigator.selectedTab) { _, _ in
            navigator.saveToDefaults()
        }
        .backgroundTask(.appRefresh("RefreshAuthToken")) {
            await authenticator.refreshAuthenticationToken()
            await registerBackgroundRefreshTask()
        }
    }

    func registerBackgroundRefreshTask() {
        let request = BGAppRefreshTaskRequest(identifier: "RefreshAuthToken")
        #if DEBUG
        request.earliestBeginDate = .now.addingTimeInterval(15)
        #else
        request.earliestBeginDate = .now.addingTimeInterval(12 * 3600)
        #endif
        try? BGTaskScheduler.shared.submit(request)
    }
}
