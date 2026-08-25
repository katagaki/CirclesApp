//
//  OnHandSync.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import Foundation
import WatchConnectivity

final class OnHandSync: NSObject, WCSessionDelegate, @unchecked Sendable {

    static let shared = OnHandSync()

    @MainActor var onIntentReceived: ((OnHandIntent) -> Void)?
    @MainActor private var lastSentPayload: OnHandPayload?
    @MainActor private var lastSentAssetsVersion: String?

    private override init() {
        super.init()
    }

    private var activeSession: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    var isWatchReachable: Bool {
        guard let activeSession else { return false }
        return activeSession.isPaired && activeSession.isWatchAppInstalled
    }

    var stateDescription: String {
        guard let activeSession else { return "unsupported" }
        return "paired=\(activeSession.isPaired) installed=\(activeSession.isWatchAppInstalled) "
            + "state=\(activeSession.activationState.rawValue) reachable=\(activeSession.isReachable)"
    }

    func activate() {
        guard let activeSession else { return }
        activeSession.delegate = self
        if activeSession.activationState != .activated {
            activeSession.activate()
        }
    }

    @MainActor
    func send(_ payload: OnHandPayload) {
        guard lastSentPayload != payload else { return }
        guard let activeSession, activeSession.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        do {
            try activeSession.updateApplicationContext([OnHandMessage.payload: data])
            lastSentPayload = payload
        } catch {
            debugPrint("OnHandSync: Failed to send payload: \(error.localizedDescription)")
        }
    }

    @MainActor
    func hasSentAssets(version: String) -> Bool {
        lastSentAssetsVersion == version
    }

    @MainActor
    func send(_ bundle: OnHandAssetBundle) {
        guard lastSentAssetsVersion != bundle.version else { return }
        guard let activeSession, activeSession.activationState == .activated else { return }
        guard let data = bundle.encoded() else { return }

        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "OnHandAssets-\(bundle.version).plist")
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            debugPrint("OnHandSync: Failed to stage assets: \(error.localizedDescription)")
            return
        }

        for transfer in activeSession.outstandingFileTransfers
        where transfer.file.metadata?[OnHandMessage.assetsVersion] as? String != bundle.version {
            transfer.cancel()
        }

        activeSession.transferFile(fileURL, metadata: [OnHandMessage.assetsVersion: bundle.version])
        lastSentAssetsVersion = bundle.version
    }

    // MARK: WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            debugPrint("OnHandSync: Activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: (any Error)?
    ) {
        try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        guard let error else { return }
        debugPrint("OnHandSync: Asset transfer failed: \(error.localizedDescription)")
        Task { @MainActor in
            OnHandSync.shared.lastSentAssetsVersion = nil
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handle(userInfo)
    }

    private nonisolated func handle(_ contents: [String: Any]) {
        guard let data = contents[OnHandMessage.intent] as? Data,
              let intent = try? JSONDecoder().decode(OnHandIntent.self, from: data) else {
            return
        }
        Task { @MainActor in
            OnHandSync.shared.onIntentReceived?(intent)
        }
    }
}
