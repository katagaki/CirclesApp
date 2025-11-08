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

    @State var orientation = Orientation()
    @State var authenticator = Authenticator()
    @State var favorites = Favorites()
    @State var database = Database()
    @State var imageCache = ImageCache()
    @State var planner = Events()
    @State var oasis = Oasis()
    @State var selections = UserSelections()
    @State var unifier = Unifier()
    @State var catalogDataManager = CatalogDataManager()
    @State var favoritesDataManager = FavoritesDataManager()

    @State var hasAppLaunchedForTheFirstTime: Bool = false

    var body: some Scene {
        WindowGroup {
            UnifiedView()
                .overlay {
                    if authenticator.onlineState == .offline {
                        ZStack(alignment: .top) {
                            Color.clear
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
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
                .onAppear {
                    orientation.update()
                }
                .onRotate { newOrientation in
                    orientation.update(to: newOrientation)
                }
        }
        .modelContainer(sharedModelContainer)
        .environment(orientation)
        .environment(authenticator)
        .environment(favorites)
        .environment(database)
        .environment(imageCache)
        .environment(planner)
        .environment(oasis)
        .environment(selections)
        .environment(unifier)
        .environment(catalogDataManager)
        .environment(favoritesDataManager)
        .onChange(of: scenePhase) { _, newValue in
            if !hasAppLaunchedForTheFirstTime {
                hasAppLaunchedForTheFirstTime = true
            } else {
                switch newValue {
                case .active:
                    if authenticator.token != nil && authenticator.onlineState == .online {
                        // Require authentication when token expires
                        if authenticator.tokenExpiryDate < .now {
                            unifier.isPresented = false
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
        .onChange(of: planner.participation) {
            planner.participationUserDefault = planner.participation
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
