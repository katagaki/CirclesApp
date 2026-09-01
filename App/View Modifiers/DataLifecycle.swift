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
    @State var pendingDownloadShouldResetSelections: Bool = true
    @State var isInitialDownload: Bool = false
    @State var previousEventNumber: Int?
    @State var isRevertingEvent: Bool = false
    @State var isUpdatingData: Bool = false
    @State var isOfflineModeDownloadAlertShowing: Bool = false

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: authenticator.isReady) { _, newValue in
                if newValue && !authenticator.isAuthenticating {
                    reloadData(animated: false)
                }
            }
            .onChange(of: authenticator.isAuthenticating) { oldValue, newValue in
                if oldValue == true && newValue == false && authenticator.token != nil {
                    reloadData(shouldResetSelections: true, animated: false)
                }
            }
            .onChange(of: unifier.shouldUpdateData) { _, newValue in
                if newValue {
                    unifier.shouldUpdateData = false
                    updateData()
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
                    planner.updateActiveEvent(onlineState: authenticator.effectiveOnlineState)
                    reloadData(forceDownload: false, shouldResetSelections: true)
                }
            }
            .alert("Alerts.DownloadConfirmation.Title", isPresented: $isDownloadConfirmationShowing) {
                Button("Shared.Download") {
                    if let event = pendingDownloadEvent {
                        if isUpdatingData {
                            database.reset()
                            database.delete(event: event)
                        }
                        oasis.open {
                            Task.detached {
                                await loadDataFromDatabase(for: event)
                                await MainActor.run {
                                    isUpdatingData = false
                                    finishReload(shouldResetSelections: pendingDownloadShouldResetSelections)
                                }
                            }
                        }
                    }
                }
                if !isInitialDownload {
                    Button("Shared.Cancel", role: .cancel) {
                        if isUpdatingData {
                            isUpdatingData = false
                            isReloadingData = false
                        } else {
                            revertToPreviousEvent()
                        }
                    }
                }
            } message: {
                Text("Alerts.DownloadConfirmation.Message \(estimatedDownloadSize)")
            }
            .alert("Alerts.OfflineMode.Download.Title", isPresented: $isOfflineModeDownloadAlertShowing) {
                Button("Shared.OK", role: .cancel) {
                    revertToPreviousEvent()
                }
            } message: {
                Text("Alerts.OfflineMode.Download.Message")
            }
    }

    func revertToPreviousEvent() {
        if let previousEventNumber {
            isRevertingEvent = true
            planner.activeEventNumber = previousEventNumber
            planner.activeEventNumberUserDefault = previousEventNumber
            planner.updateActiveEvent(onlineState: authenticator.effectiveOnlineState)
            if let activeEvent = planner.activeEvent {
                database.prepare(for: activeEvent)
            }
        }
        finishReload(shouldResetSelections: false)
    }

    func updateData() {
        guard !isReloadingData, !authenticator.isOfflineModeActive,
              let activeEvent = planner.activeEvent else { return }
        isReloadingData = true
        isUpdatingData = true
        pendingDownloadShouldResetSelections = true
        isInitialDownload = false
        Task {
            await confirmDownload(of: activeEvent)
        }
    }

    func confirmDownload(of event: WebCatalogEvent.Response.Event) async {
        let token = authenticator.token ?? OpenIDToken()
        let totalBytes = await database.fetchDownloadSizes(for: event, authToken: token)
        let sizeString: String
        if let totalBytes {
            sizeString = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        } else {
            sizeString = String(localized: "Shared.Unknown")
        }
        pendingDownloadEvent = event
        estimatedDownloadSize = sizeString
        isDownloadConfirmationShowing = true
    }

    func reloadData(forceDownload: Bool = false, shouldResetSelections: Bool = false, animated: Bool = true) {
        if !isReloadingData {
            isReloadingData = true
            unifier.animatesReload = animated
            database.reset()
            if forceDownload {
                isDatabaseInitialized = false
            }
            unifier.hide()

            Task {
                if let authToken = authenticator.token {
                    await planner.prepare(authToken: authToken)
                }
                planner.updateActiveEvent(onlineState: authenticator.effectiveOnlineState)
                let activeEvent = planner.activeEvent

                if let activeEvent {
                    if !database.isDownloaded(for: activeEvent) {
                        if authenticator.isOfflineModeActive {
                            isOfflineModeDownloadAlertShowing = true
                        } else {
                            pendingDownloadShouldResetSelections = shouldResetSelections
                            isInitialDownload = !isDatabaseInitialized
                            await confirmDownload(of: activeEvent)
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
            unifier.show(animated: unifier.animatesReload)
        }
        isReloadingData = false
        Task.detached(priority: .userInitiated) {
            await loadImages()
        }
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
                if !database.isDownloaded(for: activeEvent) {
                    UIApplication.shared.isIdleTimerDisabled = false
                    return
                }
            } else {
                database.prepare(for: activeEvent)
            }

            if oasis.isShowing {
                await oasis.setBodyText("Loading.Database")
            }
            await database.prepareIndexes(for: activeEvent)
            selections.reloadData(database: database)

            if oasis.isShowing {
                await oasis.setHeaderText("Shared.LoadingHeader.Initial")
            }

            await imageCache.loadFromDisk()
            if !isDatabaseInitialized {
                imageCache.clear()
                isDatabaseInitialized = true
            }

            database.clearDecodedImages()
        }

        UIApplication.shared.isIdleTimerDisabled = false
    }

    func loadImages() async {
        await database.loadCommonImages()
        await database.loadCircleImages()
    }

    func loadFavorites() async {
        await favorites.loadFromCache()
        if !authenticator.isOfflineModeActive {
            await favorites.refresh(authToken: authenticator.token)
        }
    }
}

extension View {
    func dataLifecycle() -> some View {
        self.modifier(DataLifecycleModifier())
    }
}
