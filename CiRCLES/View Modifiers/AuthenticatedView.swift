//
//  AuthenticatedView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import SwiftUI

struct AuthenticatedView: ViewModifier {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Oasis.self) var oasis
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    @State var isReloadingData: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    func body(content: Content) -> some View {
        @Bindable var authenticator = authenticator
        content
            .task {
                authenticator.setupReachability()
            }
            .sheet(isPresented: $authenticator.isAuthenticating) {
                LoginView()
                    .environment(authenticator)
                    .interactiveDismissDisabled()
            }
            .onChange(of: authenticator.onlineState) { _, newValue in
                switch newValue {
                case .online, .offline:
                    reloadData()
                case .undetermined: break
                }
            }
            .onChange(of: authenticator.token) { _, newValue in
                if newValue != nil {
                    reloadData()
                }
            }
            .onChange(of: planner.activeEventNumber) { oldValue, _ in
                if oldValue != -1 {
                    planner.activeEventNumberUserDefault = planner.activeEventNumber
                    planner.updateActiveEvent(onlineState: authenticator.onlineState)
                    reloadData(forceDownload: true)
                }
            }
            .onOpenURL { url in
                if url.absoluteString == circleMsCancelURLSchema {
                    authenticator.isWaitingForAuthenticationCode = false
                } else {
                    authenticator.getAuthenticationCode(from: url)
                }
            }
    }

    func reloadData(forceDownload: Bool = false) {
        if !isReloadingData {
            isReloadingData = true
            if forceDownload {
                isDatabaseInitialized = false
            }
            // Don't close unifier - let user continue interacting
            Task {
                // Prepare event data
                if let authToken = authenticator.token {
                    await planner.prepare(authToken: authToken)
                }
                planner.updateActiveEvent(onlineState: authenticator.onlineState)
                let activeEvent = planner.activeEvent
                
                // Load data in background without blocking UI
                await loadDataFromDatabase(for: activeEvent)
                await loadFavorites()
                
                // Only update selections after loading completes
                await MainActor.run {
                    // Set initial selections if needed
                    if selections.date == nil {
                        selections.date = selections.fetchDefaultDateSelection()
                    }
                    if selections.map == nil {
                        selections.map = selections.fetchDefaultMapSelection()
                    }
                    if !unifier.isPresented {
                        unifier.isPresented = true
                    }
                    isReloadingData = false
                }
            }
        }
    }

    func loadDataFromDatabase(for activeEvent: WebCatalogEvent.Response.Event? = nil) async {
        // Keep screen on for iOS 18 and below during downloads
        if #unavailable(iOS 26.0) {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        let token = authenticator.token ?? OpenIDToken()

        if let activeEvent {
            // Download databases
            await database.downloadTextDatabase(for: activeEvent, authToken: token) { _ in }
            await database.downloadImageDatabase(for: activeEvent, authToken: token) { _ in }

            // Connect to databases
            database.connect()

            if !isDatabaseInitialized {
                let actor = DataConverter(modelContainer: sharedModelContainer)

                await actor.disableAutoSave()
                await actor.deleteAll()
                imageCache.clear()

                // Load data from databases
                await actor.loadEvents(from: database.textDatabase)
                await actor.loadMaps(from: database.textDatabase)
                await actor.loadLayouts(from: database.textDatabase)
                await actor.loadGenres(from: database.textDatabase)
                await actor.loadCircles(from: database.textDatabase)

                await actor.save()
                await actor.enableAutoSave()

                isDatabaseInitialized = true
            }

            // Load images into memory
            database.imageCache.removeAll()
            database.loadCommonImages()
            database.loadCircleImages()

            database.disconnect()
        }

        // Re-enable idle timer for iOS 18 and below
        if #unavailable(iOS 26.0) {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func loadFavorites() async {
        let actor = FavoritesActor(modelContainer: sharedModelContainer)
        if let token = authenticator.token {
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        } else {
            let (items, wcIDMappedItems) = await actor.all(authToken: OpenIDToken())
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }
}

extension View {
    func authenticated() -> some View {
        self.modifier(AuthenticatedView())
    }
}
