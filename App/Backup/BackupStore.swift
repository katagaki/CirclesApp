//
//  BackupStore.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/20.
//

import Foundation
import Synchronization

struct BackupPayload: Sendable {
    let pid: Int
    let date: Date
    let deviceName: String
    let settings: Data
    let profilePicture: Data?
    let visits: Data
}

/// What a backup found in iCloud Drive says about itself, without reading it back in full.
struct BackupSnapshot: Sendable {
    let date: Date
    let deviceName: String?
}

/// Sizes of the data this device would put into its next backup.
struct BackupContents: Sendable {
    let visitBytes: Int64
    let buysBytes: Int64
    let attachmentBytes: Int64
    let settingsBytes: Int64

    var totalBytes: Int64 { visitBytes + buysBytes + attachmentBytes + settingsBytes }
}

enum BackupError: Error {
    case iCloudUnavailable
    case noBackupFound
}

final class BackupStore: Sendable {

    static let shared = BackupStore()

    static let ubiquityContainerIdentifier = "iCloud.com.tsubuzaki.KamiSeries"
    static let appGroupIdentifier = "group.com.tsubuzaki.CiRCLES"

    static let rootFolderName = "Backups"
    static let lastBackupDateFileName = "LastBackupDate"
    static let deviceNameFileName = "DeviceName"
    static let settingsFileName = "Settings.plist"
    static let profilePictureFileName = "ProfilePicture.dat"
    static let visitsFileName = "Visits.json"
    static let databasesFolderName = "Databases"

    private let cachedRootURL = Mutex<URL??>(nil)

    private init() {}

    // MARK: - Roots

    var groupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)
    }

    /// The iCloud Drive visible folder for this app. Resolving this is blocking, never call it on the main thread.
    var rootURL: URL? {
        cachedRootURL.withLock { cached in
            if let cached { return cached }
            let container = FileManager.default.url(
                forUbiquityContainerIdentifier: Self.ubiquityContainerIdentifier
            )
            let root = container?.appending(path: "Documents").appending(path: Self.rootFolderName)
            cached = .some(root)
            return root
        }
    }

    func folderURL(for pid: Int) -> URL? {
        rootURL?.appending(path: String(pid))
    }

    // MARK: - Discovery

    /// Whether a backup folder for this PID exists in iCloud Drive.
    func backupExists(for pid: Int) -> Bool {
        guard let folderURL = folderURL(for: pid) else { return false }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: folderURL.path(percentEncoded: false), isDirectory: &isDirectory
        )
        return exists && isDirectory.boolValue
    }

    func lastBackupDate(for pid: Int) -> Date? {
        guard let folderURL = folderURL(for: pid) else { return nil }
        let dateURL = folderURL.appending(path: Self.lastBackupDateFileName)
        downloadIfNeeded(dateURL)
        guard let contents = try? String(contentsOf: dateURL, encoding: .utf8) else { return nil }
        return ISO8601DateFormatter().date(from: contents.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func snapshot(for pid: Int) -> BackupSnapshot? {
        guard let date = lastBackupDate(for: pid), let folderURL = folderURL(for: pid) else { return nil }
        let deviceNameURL = folderURL.appending(path: Self.deviceNameFileName)
        downloadIfNeeded(deviceNameURL)
        let deviceName = (try? String(contentsOf: deviceNameURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return BackupSnapshot(date: date, deviceName: (deviceName?.isEmpty ?? true) ? nil : deviceName)
    }

    /// Sizes of the app group databases, split the way the backup screen lists them.
    func databaseSizes() -> (buys: Int64, attachments: Int64) {
        var buys: Int64 = 0
        var attachments: Int64 = 0
        for url in backupableDatabaseURLs() {
            let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            if url.lastPathComponent == "Attachments.db" {
                attachments += size
            } else {
                buys += size
            }
        }
        return (buys, attachments)
    }

    // MARK: - Writing

    func write(_ payload: BackupPayload) throws {
        guard let folderURL = folderURL(for: payload.pid) else {
            throw BackupError.iCloudUnavailable
        }

        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(
            writingItemAt: folderURL, options: .forMerging, error: &coordinationError
        ) { url in
            do {
                try writeContents(of: payload, to: url)
            } catch {
                writeError = error
            }
        }
        if let coordinationError { throw coordinationError }
        if let writeError { throw writeError }
    }

    private func writeContents(of payload: BackupPayload, to folderURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

        try payload.settings.write(to: folderURL.appending(path: Self.settingsFileName), options: .atomic)
        try payload.visits.write(to: folderURL.appending(path: Self.visitsFileName), options: .atomic)

        let profilePictureURL = folderURL.appending(path: Self.profilePictureFileName)
        if let profilePicture = payload.profilePicture {
            try profilePicture.write(to: profilePictureURL, options: .atomic)
        } else if fileManager.fileExists(atPath: profilePictureURL.path(percentEncoded: false)) {
            try fileManager.removeItem(at: profilePictureURL)
        }

        let databasesURL = folderURL.appending(path: Self.databasesFolderName)
        try fileManager.createDirectory(at: databasesURL, withIntermediateDirectories: true)
        for sourceURL in backupableDatabaseURLs() {
            let destinationURL = databasesURL.appending(path: sourceURL.lastPathComponent)
            guard hasChanged(sourceURL, comparedTo: destinationURL) else { continue }
            overwrite(destinationURL, with: sourceURL)
        }

        try Data(payload.deviceName.utf8).write(
            to: folderURL.appending(path: Self.deviceNameFileName), options: .atomic
        )

        let dateString = ISO8601DateFormatter().string(from: payload.date)
        try Data(dateString.utf8).write(to: folderURL.appending(path: Self.lastBackupDateFileName), options: .atomic)
    }

    private func overwrite(_ destinationURL: URL, with sourceURL: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path(percentEncoded: false)) {
            try? fileManager.removeItem(at: destinationURL)
        }
        try? fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    /// Skips recopying databases that have not been touched since the previous backup.
    private func hasChanged(_ sourceURL: URL, comparedTo destinationURL: URL) -> Bool {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey]
        guard let source = try? sourceURL.resourceValues(forKeys: keys),
              let destination = try? destinationURL.resourceValues(forKeys: keys) else {
            return true
        }
        return source.contentModificationDate != destination.contentModificationDate
            || source.fileSize != destination.fileSize
    }

    /// SQLite files in the app group that hold user data the Web Catalog API does not store.
    private func backupableDatabaseURLs() -> [URL] {
        guard let groupContainerURL else { return [] }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: groupContainerURL, includingPropertiesForKeys: nil
        )) ?? []
        return contents.filter { url in
            let name = url.lastPathComponent
            return name == "Attachments.db" || (name.hasPrefix("buys") && name.hasSuffix(".db"))
        }
    }

    // MARK: - Reading

    func read(for pid: Int) throws -> BackupPayload {
        guard backupExists(for: pid), let folderURL = folderURL(for: pid) else {
            throw BackupError.noBackupFound
        }

        downloadRecursivelyIfNeeded(folderURL)

        let settingsURL = folderURL.appending(path: Self.settingsFileName)
        let visitsURL = folderURL.appending(path: Self.visitsFileName)
        let profilePictureURL = folderURL.appending(path: Self.profilePictureFileName)
        let dateURL = folderURL.appending(path: Self.lastBackupDateFileName)

        let settings = (try? Data(contentsOf: settingsURL)) ?? Data()
        let visits = (try? Data(contentsOf: visitsURL)) ?? Data("[]".utf8)
        let profilePicture = try? Data(contentsOf: profilePictureURL)
        let dateString = (try? String(contentsOf: dateURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let date = ISO8601DateFormatter().date(from: dateString) ?? .distantPast

        let deviceName = (try? String(contentsOf: folderURL.appending(path: Self.deviceNameFileName),
                                      encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return BackupPayload(
            pid: pid, date: date, deviceName: deviceName,
            settings: settings, profilePicture: profilePicture, visits: visits
        )
    }

    /// Puts the backed up SQLite files back into the app group container.
    func restoreDatabases(for pid: Int) {
        guard let folderURL = folderURL(for: pid), let groupContainerURL else { return }
        let databasesURL = folderURL.appending(path: Self.databasesFolderName)
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: databasesURL, includingPropertiesForKeys: nil
        )) ?? []
        for sourceURL in contents where sourceURL.pathExtension == "db" {
            downloadIfNeeded(sourceURL)
            overwrite(groupContainerURL.appending(path: sourceURL.lastPathComponent), with: sourceURL)
        }
    }

    // MARK: - iCloud materialization

    private func downloadIfNeeded(_ url: URL) {
        let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        guard let status = values?.ubiquitousItemDownloadingStatus, status != .current else { return }
        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        let deadline = Date.now.addingTimeInterval(30.0)
        while Date.now < deadline {
            let updated = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if updated?.ubiquitousItemDownloadingStatus == .current { return }
            Thread.sleep(forTimeInterval: 0.25)
        }
    }

    private func downloadRecursivelyIfNeeded(_ folderURL: URL) {
        guard let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            return
        }
        for case let url as URL in enumerator {
            downloadIfNeeded(url)
        }
    }
}
