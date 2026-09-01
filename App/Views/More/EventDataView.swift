//
//  EventDataView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/05/12.
//

import SwiftUI
import RADiUS
import AXiS

struct EventDataView: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Events.self) var events
    @Environment(Unifier.self) var unifier

    @State private var stats: EventDataStorageStats?
    @State private var downloadedEvents: [DownloadedEventInfo] = []
    @State private var activeDownloads: [Int: Double?] = [:]
    @State private var pendingSwitchEvent: DownloadedEventInfo?
    @State private var pendingDownloadEvent: WebCatalogEvent.Response.Event?
    @State private var estimatedDownloadSize: String = ""
    @State private var isDownloadConfirmationShowing: Bool = false
    @State private var isDownloadFailedAlertShowing: Bool = false

    private var isOnline: Bool {
        authenticator.effectiveOnlineState == .online
    }

    var body: some View {
        List {
            Section {
                EventDataStorageBar(stats: stats)
                    .listRowSeparator(.hidden)
            } header: {
                Text("More.Storage")
            } footer: {
                Text("More.Disclaimer")
            }

            if let activeEvent = events.activeEvent {
                Section {
                    HStack(spacing: 8.0) {
                        Text("Shared.Event.\(activeEvent.number)")
                        Spacer()
                        if let activeBytes {
                            Text(ByteCountFormatter.string(fromByteCount: activeBytes, countStyle: .file))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    Button("More.UpdateData", systemImage: "arrow.triangle.2.circlepath") {
                        unifier.shouldUpdateData = true
                    }
                    .foregroundStyle(.accent)
                    .tint(.accent)
                    .disabled(!isOnline)
                } header: {
                    Text("More.SelectedEvent")
                }
            }

            if hasOtherEvents {
                Section {
                    if let inactiveDownloadedEvents {
                        ForEach(inactiveDownloadedEvents) { downloaded in
                            DownloadedEventRow(
                                info: downloaded,
                                onTap: { pendingSwitchEvent = downloaded }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Shared.Delete", role: .destructive) {
                                    deleteDownloadedEvent(downloaded)
                                }
                            }
                        }
                    }
                    if let downloadableEvents, !downloadableEvents.isEmpty {
                        ForEach(downloadableEvents, id: \.id) { event in
                            DownloadableEventRow(
                                event: event,
                                progress: activeDownloads[event.number] ?? nil,
                                isDownloading: activeDownloads.keys.contains(event.number),
                                onTap: { Task { await confirmDownload(of: event) } }
                            )
                        }
                    }
                } header: {
                    Text("More.OtherEvents")
                } footer: {
                    Text("More.ProvidedBy")
                }
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refresh()
        }
        .task {
            await refresh()
        }
        .alert(
            "Alerts.SwitchEvent.Title",
            isPresented: Binding(
                get: { pendingSwitchEvent != nil },
                set: { if !$0 { pendingSwitchEvent = nil } }
            ),
            presenting: pendingSwitchEvent
        ) { event in
            Button("Alerts.SwitchEvent.Action") {
                switchEvent(to: event)
            }
            Button("Shared.Cancel", role: .cancel) {}
        } message: { event in
            Text("Alerts.SwitchEvent.Message \(event.number)")
        }
        .alert("Alerts.DownloadConfirmation.Title", isPresented: $isDownloadConfirmationShowing) {
            downloadActions()
        } message: {
            Text("Alerts.DownloadConfirmation.Message \(estimatedDownloadSize)")
        }
        .alert("Alerts.DownloadFailed.Title", isPresented: $isDownloadFailedAlertShowing) {
            downloadActions(label: "Shared.Retry")
        } message: {
            Text("Alerts.DownloadFailed.Message")
        }
    }

    @ViewBuilder
    private func downloadActions(label: LocalizedStringKey = "Shared.Download") -> some View {
        Button(label) {
            if let event = pendingDownloadEvent {
                Task { await downloadEvent(event) }
            }
        }
        Button("Shared.Cancel", role: .cancel) {}
    }

    private var activeBytes: Int64? {
        downloadedEvents.first(where: { $0.number == events.activeEventNumber })?.bytes
    }

    private var inactiveDownloadedEvents: [DownloadedEventInfo]? {
        let inactive = downloadedEvents.filter { $0.number != events.activeEventNumber }
        return inactive.isEmpty ? nil : inactive
    }

    private var downloadableEvents: [WebCatalogEvent.Response.Event]? {
        guard isOnline, let list = events.eventData?.list else { return nil }
        let downloadedNumbers = Set(downloadedEvents.map(\.number))
        return list
            .filter { !downloadedNumbers.contains($0.number) }
            .sorted(by: { $0.number > $1.number })
    }

    private var hasOtherEvents: Bool {
        (inactiveDownloadedEvents?.isEmpty == false) || (downloadableEvents?.isEmpty == false)
    }

    private func refresh() async {
        async let collected = Task.detached(priority: .utility) {
            collectStorage()
        }.value
        async let eventListReload: Void = reloadEventList()
        let (storage, _) = await (collected, eventListReload)
        withAnimation(.smooth.speed(2.0)) {
            stats = storage.stats
            downloadedEvents = storage.downloaded
        }
    }

    private func reloadEventList() async {
        guard isOnline, let token = authenticator.token else { return }
        await events.reloadEventList(authToken: token)
    }

    private func deleteDownloadedEvent(_ downloaded: DownloadedEventInfo) {
        let event = WebCatalogEvent.Response.Event(id: 0, number: downloaded.number)
        database.delete(event: event)
        Task { await refresh() }
    }

    private func switchEvent(to downloaded: DownloadedEventInfo) {
        guard downloaded.number != events.activeEventNumber else { return }
        unifier.stackPath.removeAll()
        events.activeEventNumber = downloaded.number
    }

    private func confirmDownload(of event: WebCatalogEvent.Response.Event) async {
        guard let token = authenticator.token else { return }
        guard !activeDownloads.keys.contains(event.number) else { return }

        activeDownloads.updateValue(nil, forKey: event.number)
        let totalBytes = await database.fetchDownloadSizes(for: event, authToken: token)
        activeDownloads.removeValue(forKey: event.number)

        if let totalBytes {
            estimatedDownloadSize = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        } else {
            estimatedDownloadSize = String(localized: "Shared.Unknown")
        }
        pendingDownloadEvent = event
        isDownloadConfirmationShowing = true
    }

    private func downloadEvent(_ event: WebCatalogEvent.Response.Event) async {
        guard let token = authenticator.token else { return }
        guard !activeDownloads.keys.contains(event.number) else { return }

        if activeDownloads.isEmpty {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        activeDownloads[event.number] = 0.0

        _ = await database.download(for: event, of: .text, authToken: token) { progress in
            await MainActor.run {
                if let progress {
                    activeDownloads[event.number] = progress * 0.1
                }
            }
        }
        activeDownloads[event.number] = 0.1
        _ = await database.download(for: event, of: .images, authToken: token) { progress in
            await MainActor.run {
                if let progress {
                    activeDownloads[event.number] = 0.1 + progress * 0.9
                }
            }
        }

        activeDownloads.removeValue(forKey: event.number)
        if activeDownloads.isEmpty {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        if !database.isDownloaded(for: event) {
            isDownloadFailedAlertShowing = true
        }
        await refresh()
    }
}

extension EventDataView {

    private nonisolated func collectStorage() -> (stats: EventDataStorageStats, downloaded: [DownloadedEventInfo]) {
        let dataStoreURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let groupContainerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.CiRCLES"
        )
        let imageCacheURL = dataStoreURL?.appendingPathComponent("ImageCache", conformingTo: .folder)

        var perEventBytes: [Int: Int64] = [:]
        var databaseBytes: Int64 = 0
        if let dataStoreURL {
            let (totals, perEvent) = scanEventDatabases(at: dataStoreURL)
            databaseBytes += totals
            for (number, bytes) in perEvent {
                perEventBytes[number, default: 0] += bytes
            }
        }
        if let groupContainerURL {
            let (totals, perEvent) = scanEventDatabases(at: groupContainerURL)
            databaseBytes += totals
            for (number, bytes) in perEvent {
                perEventBytes[number, default: 0] += bytes
            }
        }

        var imageCacheBytes: Int64 = 0
        if let imageCacheURL,
           FileManager.default.fileExists(atPath: imageCacheURL.path(percentEncoded: false)) {
            imageCacheBytes = directorySize(at: imageCacheURL)
        }

        let breakdown = EventDataStorageBreakdown(
            databaseBytes: databaseBytes,
            imageCacheBytes: imageCacheBytes
        )
        let stats = EventDataStorageStats.current(breakdown: breakdown)

        let downloaded = perEventBytes
            .map { DownloadedEventInfo(number: $0.key, bytes: $0.value) }
            .sorted(by: { $0.number > $1.number })

        return (stats, downloaded)
    }

    private nonisolated func scanEventDatabases(at directory: URL) -> (total: Int64, perEvent: [Int: Int64]) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return (0, [:])
        }
        var total: Int64 = 0
        var perEvent: [Int: Int64] = [:]
        for url in contents where url.isFileURL && url.pathExtension == "db" {
            let fileName = url.lastPathComponent
            guard fileName.hasPrefix("webcatalog") else { continue }
            let stripped = fileName
                .replacingOccurrences(of: "webcatalog", with: "")
                .replacingOccurrences(of: "Image1.db", with: "")
                .replacingOccurrences(of: ".db", with: "")
            guard let eventNumber = Int(stripped) else { continue }
            let size = (try? FileManager.default.attributesOfItem(
                atPath: url.path(percentEncoded: false)
            )[.size] as? Int64) ?? 0
            total += size
            perEvent[eventNumber, default: 0] += size
        }
        return (total, perEvent)
    }

    private nonisolated func directorySize(at url: URL) -> Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return 0
        }
        var total: Int64 = 0
        for file in contents {
            if let size = try? FileManager.default.attributesOfItem(
                atPath: file.path(percentEncoded: false)
            )[.size] as? Int64 {
                total += size
            }
        }
        return total
    }

}

struct DownloadedEventInfo: Identifiable, Equatable {
    var id: Int { number }
    let number: Int
    let bytes: Int64
}
