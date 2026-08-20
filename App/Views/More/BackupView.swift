//
//  BackupView.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/20.
//

import SwiftUI

struct BackupView: View {

    @Environment(BackupManager.self) var backupManager

    var body: some View {
        @Bindable var backupManager = backupManager
        List {
            Section {
                BackupStatusHeader(backupManager: backupManager)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            if let snapshot = backupManager.remoteSnapshot, backupManager.isSnapshotFromAnotherDevice {
                Section {
                    Button("More.Backup.Restore") {
                        backupManager.promptRestore()
                    }
                    .foregroundStyle(.accent)
                    .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                } header: {
                    Text("More.Backup.Restore.Section")
                } footer: {
                    if let deviceName = snapshot.deviceName {
                        Text("More.Backup.Restore.From \(deviceName)")
                    }
                }
            }

            Section {
                Toggle("More.Backup.Enabled", isOn: $backupManager.isEnabled)
                    .disabled(backupManager.isBackingUp || backupManager.isRestoring)
                if backupManager.isEnabled {
                    Button("More.Backup.Now") {
                        if let pid = backupManager.pid {
                            Task { await backupManager.backup(pid: pid) }
                        }
                    }
                    .foregroundStyle(.accent)
                    .disabled(backupManager.pid == nil
                              || backupManager.isBackingUp || backupManager.isRestoring)
                }
            } footer: {
                Text(backupManager.isEnabled ? "More.Backup.Automatic" : "More.Backup.Disabled.Description")
            }

            Section {
                ForEach(contentRows) { row in
                    BackupContentRow(item: row)
                }
                HStack {
                    Text("More.Backup.Total")
                        .fontWeight(.medium)
                    Spacer()
                    Text(ByteCountFormatter.string(
                        fromByteCount: backupManager.contents?.totalBytes ?? 0, countStyle: .file
                    ))
                    .monospacedDigit()
                }
            } header: {
                Text("More.Backup.Contents")
            } footer: {
                Text("More.Backup.Contents.Description")
            }

            if backupManager.lastBackupFailed {
                Section {
                    Button("More.Backup.Retry") {
                        if let pid = backupManager.pid {
                            Task { await backupManager.backup(pid: pid) }
                        }
                    }
                    .foregroundStyle(.accent)
                    .disabled(backupManager.pid == nil || backupManager.isBackingUp)
                }
            }
        }
        .listSectionSpacing(.compact)
        .navigationTitle("More.Backup")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth.speed(2.0), value: backupManager.isEnabled)
        .animation(.smooth.speed(2.0), value: backupManager.isBackingUp)
        .task {
            await backupManager.loadDetails()
        }
    }

    private var contentRows: [BackupContentItem] {
        let contents = backupManager.contents
        return [
            BackupContentItem(id: "Visits", name: "More.Backup.Contents.Visits",
                              systemImage: "checkmark.circle", bytes: contents?.visitBytes ?? 0),
            BackupContentItem(id: "Buys", name: "More.Backup.Contents.Buys",
                              systemImage: "yensign.circle", bytes: contents?.buysBytes ?? 0),
            BackupContentItem(id: "Attachments", name: "Circles.Attachments",
                              systemImage: "paperclip", bytes: contents?.attachmentBytes ?? 0),
            BackupContentItem(id: "Settings", name: "More.Backup.Contents.Settings",
                              systemImage: "gearshape", bytes: contents?.settingsBytes ?? 0)
        ]
    }
}

private struct BackupContentItem: Identifiable {
    let id: String
    let name: LocalizedStringKey
    let systemImage: String
    let bytes: Int64
}

private struct BackupContentRow: View {

    let item: BackupContentItem

    var body: some View {
        HStack(spacing: 12.0) {
            Image(systemName: item.systemImage)
                .foregroundStyle(.accent)
                .frame(width: 24.0)
            Text(item.name)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: item.bytes, countStyle: .file))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

private struct BackupStatusHeader: View {

    let backupManager: BackupManager

    var body: some View {
        VStack(spacing: 14.0) {
            Image(systemName: glyph)
                .font(.system(size: 52.0))
                .foregroundStyle(tint)
                .symbolVariant(.fill)
                .frame(height: 62.0)

            VStack(spacing: 4.0) {
                Text(headline)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                subheadline
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if backupManager.isBackingUp {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12.0)
    }

    private var glyph: String {
        if backupManager.isBackingUp { return "arrow.trianglehead.2.clockwise.rotate.90.icloud" }
        if backupManager.lastBackupFailed { return "exclamationmark.icloud" }
        if backupManager.isSnapshotFromAnotherDevice { return "icloud.and.arrow.down" }
        if !backupManager.isEnabled { return "icloud.slash" }
        return "checkmark.icloud"
    }

    private var tint: Color {
        if backupManager.lastBackupFailed { return .orange }
        if !backupManager.isEnabled { return .secondary }
        return .accent
    }

    private var headline: LocalizedStringKey {
        if backupManager.isBackingUp { return "More.Backup.Status.InProgress" }
        if backupManager.lastBackupFailed { return "More.Backup.Status.Failed" }
        if backupManager.isSnapshotFromAnotherDevice { return "More.Backup.Status.RestoreAvailable" }
        if !backupManager.isEnabled { return "More.Backup.Status.Off" }
        return "More.Backup.Status.BackedUp"
    }

    @ViewBuilder
    private var subheadline: some View {
        if backupManager.isBackingUp {
            Text("More.Backup.Status.InProgress.Description")
        } else if backupManager.lastBackupFailed {
            Text("More.Backup.Status.Failed.Description")
        } else if !backupManager.isEnabled {
            Text("More.Backup.Status.Off.Description")
        } else if let lastBackupDate = backupManager.lastBackupDate {
            Text("More.Backup.LastBackedUp \(lastBackupDate.formatted(date: .abbreviated, time: .shortened))")
        } else {
            Text("More.Backup.Status.NotBackedUp")
        }
    }
}
