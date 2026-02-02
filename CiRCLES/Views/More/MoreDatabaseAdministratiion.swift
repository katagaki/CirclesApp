//
//  MoreDatabase.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import SQLite
import SwiftUI

typealias View = SwiftUI.View

struct MoreDatabaseAdministratiion: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(Events.self) var events
    @Environment(ImageCache.self) var imageCache
    @Environment(Oasis.self) var oasis

    @State var files: [String: URL] = [:]

    @AppStorage(wrappedValue: false, "More.DBAdmin.SkipDownload") var willSkipDownload: Bool

    var body: some View {
        List {
            Section {
                Toggle("More.DBAdmin.SkipDownload", isOn: $willSkipDownload)
                Button("More.DBAdmin.RepairData", role: .destructive) {
                    oasis.open {
                        Task {
                            await repairData()
                        }
                    }
                }
            }
            Section {
                if let imageCacheDirectory = ImageCache.cacheURL,
                   FileManager.default.fileExists(atPath: imageCacheDirectory.path()) {
                    HStack {
                        Text("More.DBAdmin.ImageCache")
                        Spacer()
                        if let folderSizeString = folderSize(of: imageCacheDirectory) {
                            Text(folderSizeString)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Shared.Clear", role: .destructive) {
                            imageCache.clear()
                        }
                    }
                }
                ForEach(files.keys.sorted(), id: \.self) { fileName in
                    HStack {
                        Text(fileName)
                        Spacer()
                        if let fileURL = files[fileName], let fileSizeString = fileSize(of: fileURL.path()) {
                            Text(fileSizeString)
                                .foregroundStyle(.secondary)
                        }
                    }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Shared.Delete", role: .destructive) {
                                if let fileURL = files[fileName] {
                                    do {
                                        try FileManager.default.removeItem(at: fileURL)
                                        files.removeValue(forKey: fileName)
                                    } catch {
                                        debugPrint(error.localizedDescription)
                                    }
                                }
                            }
                        }
                }
            } header: {
                Text("More.DBAdmin.DownloadedData")
            }
        }
        .navigationTitle("ViewTitle.More.DBAdmin")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshDownloadedDataList()
        }
    }

    func refreshDownloadedDataList() {
        var files: [String: URL] = [:]
        if let dataStoreURL = database.dataStoreURL,
           let downloadedFiles = try? FileManager.default.contentsOfDirectory(
            at: dataStoreURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
           ) {
            for file in downloadedFiles where file.isFileURL && file.pathExtension == "db" {
                var fileName = file.lastPathComponent
                fileName = fileName.replacingOccurrences(of: "webcatalog", with: "C")
                fileName = fileName.replacingOccurrences(
                    of: "Image1.db",
                    with: String(localized: "More.DBAdmin.ImageData")
                )
                fileName = fileName.replacingOccurrences(
                    of: ".db",
                    with: String(localized: "More.DBAdmin.TextData")
                )
                files[fileName] = file
            }
        }
        withAnimation(.smooth.speed(2.0)) {
            self.files = files
        }
    }

    func fileSize(of path: String) -> String? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attributes[.size] as? UInt64 {
                return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return nil
    }

    func folderSize(of url: URL) -> String? {
        if let files = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            var totalSize: UInt64 = 0
            for file in files {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: file.path())
                    if let size = attributes[.size] as? UInt64 {
                        totalSize += size
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
            return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
        }
        return nil
    }

    func repairData() async {
        UIApplication.shared.isIdleTimerDisabled = true
        oasis.open()
        if !willSkipDownload {
            if let token = authenticator.token {
                var eventToRepair: WebCatalogEvent.Response.Event?
                if let activeEvent = events.activeEvent {
                    eventToRepair = activeEvent
                } else if let eventData = await WebCatalog.events(authToken: token),
                          let activeEvent = eventData.list.first(
                            where: { $0.number == events.activeEventNumber }
                          ) {
                    eventToRepair = WebCatalogEvent.Response.Event(
                        id: activeEvent.id,
                        number: events.activeEventNumber
                    )
                }

                if let eventToRepair {
                    database.delete(event: eventToRepair)
                    await oasis.setBodyText("Loading.DownloadTextDatabase")
                    await database.downloadTextDatabase(for: eventToRepair, authToken: token) { progress in
                        await oasis.setProgress(progress)
                    }
                    await oasis.setBodyText("Loading.DownloadImageDatabase")
                    await database.downloadImageDatabase(for: eventToRepair, authToken: token) { progress in
                        await oasis.setProgress(progress)
                    }
                }
            }
        }

        refreshDownloadedDataList()
        oasis.close()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
