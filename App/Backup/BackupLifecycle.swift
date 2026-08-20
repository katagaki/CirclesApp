//
//  BackupLifecycle.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/20.
//

import SwiftUI
import RADiUS

struct BackupLifecycleModifier: ViewModifier {

    @Environment(\.scenePhase) var scenePhase
    @Environment(Authenticator.self) var authenticator
    @Environment(BackupManager.self) var backupManager
    @Environment(Events.self) var planner
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: 0, "My.LastKnownPID") var lastKnownPID: Int

    func body(content: Content) -> some View {
        @Bindable var backupManager = backupManager
        content
            .task(id: authenticator.token?.accessToken) {
                await resolvePID()
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .background {
                    backupInBackground()
                }
            }
            .alert("Alerts.Backup.Restore.Title", isPresented: $backupManager.isRestorePromptShowing) {
                Button("Alerts.Backup.Restore.Restore") {
                    if let pid = backupManager.restorablePID {
                        beginRestore(pid: pid)
                    }
                }
                Button("Alerts.Backup.Restore.Skip", role: .cancel) {
                    backupManager.declineRestore()
                }
            } message: {
                Text("Alerts.Backup.Restore.Message")
            }
    }

    func resolvePID() async {
        guard !authenticator.isOfflineModeActive,
              let token = authenticator.token, !token.accessToken.isEmpty else {
            if backupManager.pid == nil, lastKnownPID != 0 {
                backupManager.pid = lastKnownPID
            }
            return
        }
        if let userInfo = await User.info(authToken: token) {
            lastKnownPID = userInfo.pid
            await backupManager.prepare(pid: userInfo.pid)
        } else if lastKnownPID != 0 {
            await backupManager.prepare(pid: lastKnownPID)
        }
    }

    /// Keeps the app alive long enough for the file copies to land when it is being suspended.
    func backupInBackground() {
        Task {
            let identifier = UIApplication.shared.beginBackgroundTask(withName: "Backup")
            await backupManager.backupIfNeeded()
            if identifier != .invalid {
                UIApplication.shared.endBackgroundTask(identifier)
            }
        }
    }

    func beginRestore(pid: Int) {
        unifier.hide()
        oasis.open {
            Task {
                await oasis.setHeaderText("Shared.LoadingHeader.Restore")
                await oasis.setBodyText("Loading.Restore")
                await backupManager.restore(pid: pid)
                planner.participation = planner.participationUserDefault
                oasis.close()
                unifier.show()
            }
        }
    }
}

extension View {
    func backupLifecycle() -> some View {
        self.modifier(BackupLifecycleModifier())
    }
}
