//
//  Authenticator+OfflineMode.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/07/22.
//

import Foundation
import RADiUS

extension Authenticator {

    var effectiveOnlineState: OnlineState {
        isOfflineModeActive ? .offline : onlineState
    }

    var canUseOfflineMode: Bool {
        UserDefaults.standard.bool(forKey: hasAuthenticatedOnceKey) &&
        UserDefaults.standard.bool(forKey: databaseInitializedKey)
    }

    func enterOfflineMode() {
        UserDefaults.standard.set(
            Date.now.addingTimeInterval(offlineModeDuration),
            forKey: offlineModeExpiryDateKey
        )
        isOfflineModeActive = true
        restoreOfflineModeSession()
        isAuthenticating = false
    }

    func restoreOfflineModeSession() {
        if let storedToken = loadStoredToken(), !storedToken.accessToken.isEmpty {
            token = storedToken
            tokenExpiryDate = (UserDefaults.standard.object(forKey: tokenExpiryDateKey) as? Date) ?? .distantPast
        } else {
            useOfflineAuthenticationToken()
        }
    }

    func exitOfflineMode() {
        UserDefaults.standard.removeObject(forKey: offlineModeExpiryDateKey)
        isOfflineModeActive = false
        if restoreAuthenticationFromKeychainAndDefaults() {
            if onlineState == .online && tokenExpiryDate.addingTimeInterval(-3600) < .now {
                Task { await refreshAuthenticationToken() }
            }
        } else {
            isAuthenticating = true
        }
    }

    func enforceOfflineModeExpiry() {
        guard isOfflineModeActive else { return }
        let offlineModeExpiryDate = UserDefaults.standard.object(forKey: offlineModeExpiryDateKey) as? Date
        if offlineModeExpiryDate == nil || offlineModeExpiryDate! <= .now {
            exitOfflineMode()
        }
    }
}
