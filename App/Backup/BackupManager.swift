//
//  BackupManager.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/20.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class BackupManager {

    static let isEnabledKey = "Backup.Enabled"
    static let profilePictureKey = "My.ProfilePicture"

    /// Everything the app keeps in user defaults that the Web Catalog API does not hold.
    /// Auth state, cache bookkeeping and review prompt counters are deliberately left out.
    static let backedUpDefaultsKeys: [String] = [
        "Circles.Detail.HiddenSections",
        "Circles.Detail.SectionOrder",
        "Circles.DisplayMode",
        "Circles.GridSize",
        "Circles.ListSize",
        "Customization.DoubleTapToVisit",
        "Customization.ShowDay",
        "Customization.ShowSpaceName",
        "Customization.ShowWebCut",
        "Customization.UseDarkModeMaps",
        "Customization.UseHighResolutionMaps",
        "Customization.UseZoomTransition",
        "Favorites.DisplayMode",
        "Favorites.GridDisplayMode",
        "Favorites.GroupByColor",
        "Favorites.ListDisplayMode",
        "Map.ScrollType",
        "Map.ShowsGenreOverlays",
        "Map.ZoomDivisor",
        "Map.ZoomScale",
        "My.LastKnownNickname",
        "My.Participation",
        "PrivacyMode.On"
    ]

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.isEnabledKey)
            if isEnabled {
                Task { await backupIfNeeded(force: true) }
            }
        }
    }

    var isBackingUp: Bool = false
    var isRestoring: Bool = false
    var lastBackupDate: Date?
    var lastBackupFailed: Bool = false

    /// PID a restorable backup was found for, which drives the restore prompt.
    var restorablePID: Int?
    var isRestorePromptShowing: Bool = false

    @ObservationIgnored var pid: Int?

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.isEnabledKey)
    }

    // MARK: - Restore discovery

    func restoreCheckKey(for pid: Int) -> String {
        "Backup.RestoreChecked.\(pid)"
    }

    func hasCheckedForRestore(pid: Int) -> Bool {
        UserDefaults.standard.bool(forKey: restoreCheckKey(for: pid))
    }

    func markRestoreChecked(pid: Int) {
        UserDefaults.standard.set(true, forKey: restoreCheckKey(for: pid))
    }

    /// Called once the signed in user's PID is known. Offers a restore when this install has
    /// never looked for one and a folder for the PID exists.
    func prepare(pid: Int) async {
        self.pid = pid
        let store = BackupStore.shared
        let date = await Task.detached { store.lastBackupDate(for: pid) }.value
        lastBackupDate = date

        guard !hasCheckedForRestore(pid: pid) else { return }
        let exists = await Task.detached { store.backupExists(for: pid) }.value
        guard exists else {
            markRestoreChecked(pid: pid)
            return
        }
        restorablePID = pid
        isRestorePromptShowing = true
    }

    func promptRestore() {
        guard let pid else { return }
        restorablePID = pid
        isRestorePromptShowing = true
    }

    func declineRestore() {
        if let restorablePID {
            markRestoreChecked(pid: restorablePID)
        }
        restorablePID = nil
    }

    // MARK: - Backup

    func backupIfNeeded(force: Bool = false) async {
        guard isEnabled, let pid, !isBackingUp, !isRestoring else { return }
        if !force, let lastBackupDate, lastBackupDate.addingTimeInterval(3600.0) > .now { return }
        await backup(pid: pid)
    }

    func backup(pid: Int) async {
        guard !isBackingUp, !isRestoring else { return }
        isBackingUp = true
        defer { isBackingUp = false }

        let settings = settingsData()
        let profilePicture = UserDefaults.standard.data(forKey: Self.profilePictureKey)
        let actor = BackupActor(modelContainer: sharedModelContainer)
        let visits = await actor.visitsData()
        let payload = BackupPayload(
            pid: pid, date: .now, settings: settings, profilePicture: profilePicture, visits: visits
        )

        let succeeded = await Task.detached {
            do {
                try BackupStore.shared.write(payload)
                return true
            } catch {
                debugPrint("BackupManager: Backup failed: \(error.localizedDescription)")
                return false
            }
        }.value

        lastBackupFailed = !succeeded
        if succeeded {
            lastBackupDate = payload.date
            markRestoreChecked(pid: pid)
        }
    }

    // MARK: - Restore

    func restore(pid: Int) async {
        guard !isRestoring else { return }
        isRestoring = true
        defer {
            isRestoring = false
            restorablePID = nil
        }

        let payload = await Task.detached { () -> BackupPayload? in
            let store = BackupStore.shared
            guard let payload = try? store.read(for: pid) else { return nil }
            store.restoreDatabases(for: pid)
            return payload
        }.value

        guard let payload else {
            markRestoreChecked(pid: pid)
            return
        }

        applySettings(payload.settings)
        if let profilePicture = payload.profilePicture {
            UserDefaults.standard.set(profilePicture, forKey: Self.profilePictureKey)
        }
        let actor = BackupActor(modelContainer: sharedModelContainer)
        await actor.restoreVisits(from: payload.visits)

        lastBackupDate = payload.date
        markRestoreChecked(pid: pid)
    }

    // MARK: - Settings serialization

    private func settingsData() -> Data {
        var settings: [String: Any] = [:]
        for key in Self.backedUpDefaultsKeys {
            if let value = UserDefaults.standard.object(forKey: key) {
                settings[key] = value
            }
        }
        return (try? PropertyListSerialization.data(
            fromPropertyList: settings, format: .binary, options: 0
        )) ?? Data()
    }

    private func applySettings(_ data: Data) {
        guard !data.isEmpty,
              let settings = try? PropertyListSerialization.propertyList(
                  from: data, options: [], format: nil
              ) as? [String: Any] else { return }
        for (key, value) in settings where Self.backedUpDefaultsKeys.contains(key) {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
}
