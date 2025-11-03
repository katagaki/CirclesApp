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
            unifier.isPresented = false
            oasis.open {
                Task {
                    await oasis.setHeaderText("Shared.LoadingHeader.Event")
                    await oasis.setBodyText("Loading.FetchEventData")
                    if let authToken = authenticator.token {
                        await planner.prepare(authToken: authToken)
                    }
                    planner.updateActiveEvent(onlineState: authenticator.onlineState)
                    let activeEvent = planner.activeEvent
                    
                    // Load data from database first (modal phase)
                    await loadDataFromDatabase(for: activeEvent)
                    
                    // Then load favorites in background (non-modal)
                    await oasis.setModality(false)
                    await loadFavorites()
                    
                    // Only update UI and close progress after everything is done
                    await MainActor.run {
                        oasis.close()
                        // Set initial selections
                        if selections.date == nil {
                            selections.date = selections.fetchDefaultDateSelection()
                        }
                        if selections.map == nil {
                            selections.map = selections.fetchDefaultMapSelection()
                        }
                        unifier.isPresented = true
                        isReloadingData = false
                    }
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
            await oasis.setHeaderText("Shared.LoadingHeader.Download")
            await oasis.setBodyText("Loading.DownloadTextDatabase")
            await database.downloadTextDatabase(for: activeEvent, authToken: token) { progress in
                await oasis.setProgress(progress)
                await oasis.checkAndShowOfflineOption()
            }
            await oasis.setBodyText("Loading.DownloadImageDatabase")
            await database.downloadImageDatabase(for: activeEvent, authToken: token) { progress in
                await oasis.setProgress(progress)
                await oasis.checkAndShowOfflineOption()
            }

            await oasis.setBodyText("Loading.Database")
            database.connect()

            await oasis.setHeaderText("Shared.LoadingHeader.Initial")

            if !isDatabaseInitialized {

                let actor = DataConverter(modelContainer: sharedModelContainer)

                await actor.disableAutoSave()
                await actor.deleteAll()
                imageCache.clear()

                await oasis.setBodyText("Loading.Events")
                await actor.loadEvents(from: database.textDatabase)
                await oasis.checkAndShowOfflineOption()
                await oasis.setBodyText("Loading.Maps")
                await actor.loadMaps(from: database.textDatabase)
                await oasis.checkAndShowOfflineOption()
                await actor.loadLayouts(from: database.textDatabase)
                await oasis.setBodyText("Loading.Genres")
                await actor.loadGenres(from: database.textDatabase)
                await oasis.checkAndShowOfflineOption()
                await oasis.setBodyText("Loading.Circles")
                await actor.loadCircles(from: database.textDatabase)
                await oasis.checkAndShowOfflineOption()

                await actor.save()
                await actor.enableAutoSave()

                isDatabaseInitialized = true
            }

            await oasis.setBodyText("Loading.Images")
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
        await oasis.setModality(false)
        await oasis.setHeaderText("Shared.LoadingHeader.Favorites")
        await oasis.setBodyText("Loading.Favorites")
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
