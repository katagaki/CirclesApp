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
    let settings: Data
    let profilePicture: Data?
    let visits: Data
}

enum BackupError: Error {
    case noStorageAvailable
    case noBackupFound
}

enum BackupLocation: Sendable {
    case iCloud
    case local
}

final class BackupStore: Sendable {

    static let shared = BackupStore()

    static let ubiquityContainerIdentifier = "iCloud.com.tsubuzaki.CiRCLES"
    static let appGroupIdentifier = "group.com.tsubuzaki.CiRCLES"

    static let rootFolderName = "Backups"
    static let lastBackupDateFileName = "LastBackupDate"
    static let settingsFileName = "Settings.plist"
    static let profilePictureFileName = "ProfilePicture.dat"
    static let visitsFileName = "Visits.json"
    static let databasesFolderName = "Databases"

    private let cachedICloudRootURL = Mutex<URL??>(nil)

    private init() {}

    // MARK: - Roots

    var groupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)
    }

    /// The iCloud Drive visible folder for this app. Resolving this is blocking, never call it on the main thread.
    var iCloudRootURL: URL? {
        cachedICloudRootURL.withLock { cached in
            if let cached { return cached }
            let container = FileManager.default.url(
                forUbiquityContainerIdentifier: Self.ubiquityContainerIdentifier
            )
            let root = container?.appending(path: "Documents").appending(path: Self.rootFolderName)
            cached = .some(root)
            return root
        }
    }

    var localRootURL: URL? {
        groupContainerURL?.appending(path: Self.rootFolderName)
    }

    func folderURL(for pid: Int, in location: BackupLocation) -> URL? {
        let root = location == .iCloud ? iCloudRootURL : localRootURL
        return root?.appending(path: String(pid))
    }

    // MARK: - Discovery

    /// Whether a backup folder for this PID exists, preferring iCloud Drive over the local mirror.
    func backupExists(for pid: Int) -> Bool {
        locationOfBackup(for: pid) != nil
    }

    func locationOfBackup(for pid: Int) -> BackupLocation? {
        for location in [BackupLocation.iCloud, .local] {
            guard let folderURL = folderURL(for: pid, in: location) else { continue }
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: folderURL.path(percentEncoded: false),
                                              isDirectory: &isDirectory), isDirectory.boolValue {
                return location
            }
        }
        return nil
    }

    func lastBackupDate(for pid: Int) -> Date? {
        for location in [BackupLocation.iCloud, .local] {
            guard let folderURL = folderURL(for: pid, in: location) else { continue }
            let dateURL = folderURL.appending(path: Self.lastBackupDateFileName)
            downloadIfNeeded(dateURL)
            guard let contents = try? String(contentsOf: dateURL, encoding: .utf8) else { continue }
            if let date = ISO8601DateFormatter().date(from: contents.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }
        return nil
    }

    // MARK: - Writing

    func write(_ payload: BackupPayload) throws {
        guard let localFolderURL = folderURL(for: payload.pid, in: .local) else {
            throw BackupError.noStorageAvailable
        }

        try writeContents(of: payload, to: localFolderURL)

        guard let iCloudFolderURL = folderURL(for: payload.pid, in: .iCloud) else { return }
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(
            writingItemAt: iCloudFolderURL, options: .forMerging, error: &coordinationError
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
        guard let location = locationOfBackup(for: pid),
              let folderURL = folderURL(for: pid, in: location) else {
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

        return BackupPayload(
            pid: pid, date: date, settings: settings, profilePicture: profilePicture, visits: visits
        )
    }

    /// Puts the backed up SQLite files back into the app group container.
    func restoreDatabases(for pid: Int) {
        guard let location = locationOfBackup(for: pid),
              let folderURL = folderURL(for: pid, in: location),
              let groupContainerURL else { return }
        let fileManager = FileManager.default
        let databasesURL = folderURL.appending(path: Self.databasesFolderName)
        let contents = (try? fileManager.contentsOfDirectory(at: databasesURL, includingPropertiesForKeys: nil)) ?? []
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
