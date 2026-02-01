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
            .onChange(of: authenticator.isReady) { _, newValue in
                if newValue && !authenticator.isAuthenticating {
                    reloadData()
                }
            }
            .onChange(of: authenticator.isAuthenticating) { oldValue, newValue in
                if oldValue == true && newValue == false && authenticator.token != nil {
                    reloadData()
                }
            }
            .onChange(of: planner.activeEventNumber) { oldValue, _ in
                if oldValue != -1 {
                    planner.activeEventNumberUserDefault = planner.activeEventNumber
                    planner.updateActiveEvent(onlineState: authenticator.onlineState)
                    reloadData(forceDownload: false, shouldResetSelections: true)
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

    func reloadData(forceDownload: Bool = false, shouldResetSelections: Bool = false) {
        if !isReloadingData {
            isReloadingData = true
            database.reset()
            if forceDownload {
                isDatabaseInitialized = false
            }
            unifier.hide()

            Task {
                if let authToken = authenticator.token {
                    await planner.prepare(authToken: authToken)
                }
                planner.updateActiveEvent(onlineState: authenticator.onlineState)
                let activeEvent = planner.activeEvent

                if let activeEvent {
                    if !database.isDownloaded(for: activeEvent) {
                        oasis.open {
                            Task.detached {
                                await loadDataFromDatabase(for: activeEvent)
                                await MainActor.run {
                                    finishReload(shouldResetSelections: shouldResetSelections)
                                }
                            }
                        }
                    } else {
                        await loadDataFromDatabase(for: activeEvent)
                        finishReload(shouldResetSelections: shouldResetSelections)
                    }
                } else {
                    finishReload(shouldResetSelections: shouldResetSelections)
                }
            }
        }
    }

    @MainActor
    func finishReload(shouldResetSelections: Bool = false) {
        oasis.close()
        // Set initial selections
        if shouldResetSelections || selections.date == nil {
            selections.date = selections.fetchDefaultDateSelection(database: database)
        }
        if shouldResetSelections || selections.map == nil {
            selections.map = selections.fetchDefaultMapSelection(database: database)
        }

        if !authenticator.isAuthenticating {
            unifier.show()
        }
        isReloadingData = false
        Task.detached(priority: .background) {
            await loadFavorites()
        }
    }

    func loadDataFromDatabase(for activeEvent: WebCatalogEvent.Response.Event? = nil) async {
        UIApplication.shared.isIdleTimerDisabled = true

        let token = authenticator.token ?? OpenIDToken()

        if let activeEvent {
            if !database.isDownloaded(for: activeEvent) {
                await oasis.setHeaderText("Shared.LoadingHeader.Download")
                await oasis.setBodyText("Loading.DownloadTextDatabase")
                await database.downloadTextDatabase(for: activeEvent, authToken: token) { progress in
                    await oasis.setProgress(progress)
                }
                await oasis.setBodyText("Loading.DownloadImageDatabase")
                await database.downloadImageDatabase(for: activeEvent, authToken: token) { progress in
                    await oasis.setProgress(progress)
                }
            } else {
                await database.downloadTextDatabase(for: activeEvent, authToken: token) { _ in }
                await database.downloadImageDatabase(for: activeEvent, authToken: token) { _ in }
            }

            if oasis.isShowing {
                await oasis.setBodyText("Loading.Database")
            }
            database.connect()
            selections.reloadData(database: database)

            if oasis.isShowing {
                await oasis.setHeaderText("Shared.LoadingHeader.Initial")
            }

            if !isDatabaseInitialized {
                imageCache.clear()
                isDatabaseInitialized = true
            }

            database.imageCache.removeAll()
            database.loadCommonImages()
            database.loadCircleImages()
            database.disconnect()
        }

        UIApplication.shared.isIdleTimerDisabled = false
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
