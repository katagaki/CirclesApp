//
//  DataLifecycle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import SwiftUI
import RADiUS
import AXiS

struct DataLifecycleModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Oasis.self) var oasis
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    @State var isReloadingData: Bool = false
    @State var isDownloadConfirmationShowing: Bool = false
    @State var estimatedDownloadSize: String = ""
    @State var pendingDownloadEvent: WebCatalogEvent.Response.Event?
    @State var previousEventNumber: Int?
    @State var isRevertingEvent: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: authenticator.isReady) { _, newValue in
                if newValue && !authenticator.isAuthenticating {
                    reloadData()
                }
            }
            .onChange(of: authenticator.isAuthenticating) { oldValue, newValue in
                if oldValue == true && newValue == false && authenticator.token != nil {
                    reloadData(shouldResetSelections: true)
                }
            }
            .onChange(of: planner.activeEventNumber) { oldValue, _ in
                if isRevertingEvent {
                    isRevertingEvent = false
                    return
                }
                if oldValue != -1 {
                    previousEventNumber = oldValue
                    database.disconnect()
                    planner.activeEventNumberUserDefault = planner.activeEventNumber
                    planner.updateActiveEvent(onlineState: authenticator.onlineState)
                    reloadData(forceDownload: false, shouldResetSelections: true)
                }
            }
            .alert("Alerts.DownloadConfirmation.Title", isPresented: $isDownloadConfirmationShowing) {
                Button("Shared.Download") {
                    if let event = pendingDownloadEvent {
                        oasis.open {
                            Task.detached {
                                await loadDataFromDatabase(for: event)
                                await MainActor.run {
                                    finishReload(shouldResetSelections: true)
                                }
                            }
                        }
                    }
                }
                Button("Shared.Cancel", role: .cancel) {
                    if let previousEventNumber {
                        isRevertingEvent = true
                        planner.activeEventNumber = previousEventNumber
                        planner.activeEventNumberUserDefault = previousEventNumber
                        planner.updateActiveEvent(onlineState: authenticator.onlineState)
                        if let activeEvent = planner.activeEvent {
                            database.prepare(for: activeEvent)
                        }
                    }
                    finishReload(shouldResetSelections: false)
                }
            } message: {
                Text("Alerts.DownloadConfirmation.Message \(estimatedDownloadSize)")
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
                        if isDatabaseInitialized {
                            let token = authenticator.token ?? OpenIDToken()
                            let totalBytes = await database.fetchDownloadSizes(
                                for: activeEvent, authToken: token
                            )
                            let sizeString: String
                            if let totalBytes {
                                sizeString = ByteCountFormatter.string(
                                    fromByteCount: totalBytes, countStyle: .file
                                )
                            } else {
                                sizeString = String(localized: "Shared.Unknown")
                            }
                            pendingDownloadEvent = activeEvent
                            estimatedDownloadSize = sizeString
                            isDownloadConfirmationShowing = true
                        } else {
                            oasis.open {
                                Task.detached {
                                    await loadDataFromDatabase(for: activeEvent)
                                    await MainActor.run {
                                        finishReload(shouldResetSelections: shouldResetSelections)
                                    }
                                }
                            }
                        }
                    } else {
                        Task.detached {
                            await loadDataFromDatabase(for: activeEvent)
                            await MainActor.run {
                                finishReload(shouldResetSelections: shouldResetSelections)
                            }
                        }
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

        if shouldResetSelections {
            selections.resetSelections()
        }

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
                database.prepare(for: activeEvent)
            }

            if oasis.isShowing {
                await oasis.setBodyText("Loading.Database")
            }
            selections.reloadData(database: database)

            if oasis.isShowing {
                await oasis.setHeaderText("Shared.LoadingHeader.Initial")
            }

            await imageCache.loadFromDisk()
            if !isDatabaseInitialized {
                imageCache.clear()
                isDatabaseInitialized = true
            }

            database.imageCache.removeAll()
            async let commonLoad: Void = database.loadCommonImages()
            async let circleLoad: Void = database.loadCircleImages()
            _ = await (commonLoad, circleLoad)
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
    func dataLifecycle() -> some View {
        self.modifier(DataLifecycleModifier())
    }
}
