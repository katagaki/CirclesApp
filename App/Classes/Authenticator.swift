//
//  Authenticator.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

import CloudKit
import Foundation
import KeychainAccess
import Reachability
import RADiUS

@Observable
@MainActor
class Authenticator {

    @ObservationIgnored let keychain = Keychain(service: "com.tsubuzaki.CiRCLES")
    @ObservationIgnored let keychainAuthTokenKey: String = "CircleMsAuthToken"
    @ObservationIgnored let keychainClientKey: String = "OpenIDClientConfig"
    @ObservationIgnored let tokenExpiryDateKey: String = "Auth.TokenExpiryDate"
    @ObservationIgnored let remoteConfigFetchDateKey: String = "RemoteConfig.LastFetchDate"
    @ObservationIgnored let remoteConfigFetchInterval: TimeInterval = 604800
    @ObservationIgnored let reachability = try? Reachability()

    var isAuthenticating: Bool = false
    var isWaitingForAuthenticationCode: Bool = false
    var isReady: Bool = false
    var onlineState: OnlineState = .undetermined

    var code: String?
    var token: OpenIDToken?
    var tokenExpiryDate: Date = .distantFuture

    var authBroadcastMessage: String?
    var isLoginAvailable: Bool = true
    var isAuthEnabled: Bool = true
    var isFetchingLoginInformation: Bool = false

    @ObservationIgnored var client: OpenIDClient?

    var canLogin: Bool {
        isAuthEnabled && isLoginAvailable && client != nil
    }

    var authURL: URL? {
        guard let client else { return nil }
        let baseURL = circleMsAuthEndpoint.appending(path: "OAuth2")
        let responseType = "code"
        let clientID = client.id
        let redirectURI = client.redirectURL
        let state = "auth"
        let scope = "circle_read circle_write favorite_read favorite_write user_info"

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scope)
        ]

        return components?.url
    }

    init() {
        self.client = nil
        self.client = restoreClientFromKeychain()
    }

    func refreshLoginInformation() async {
        guard !isFetchingLoginInformation else { return }
        isFetchingLoginInformation = true
        defer { isFetchingLoginInformation = false }
        async let broadcastMessage: Void = refreshBroadcastMessage()
        async let clientConfig: Void = refreshClientConfigIfNeeded()
        _ = await (broadcastMessage, clientConfig)
    }

    func refreshBroadcastMessage() async {
        let provider = RemoteConfigProvider()

        guard await provider.accountStatus() == .available else {
            // Login only requires iCloud when the client configuration has not been cached yet
            if client == nil {
                let isJapanese = Locale.current.language.languageCode?.identifier == "ja"
                self.authBroadcastMessage = isJapanese
                    ? "ログインするには、iCloudにサインインしてください。"
                    : "Please sign in to iCloud to continue."
            }
            return
        }

        switch await provider.fetchBroadcastMessage() {
        case .found(let message, let authEnabled):
            self.authBroadcastMessage = message
            self.isLoginAvailable = true
            self.isAuthEnabled = authEnabled
        case .notFound:
            if client == nil {
                let isJapanese = Locale.current.language.languageCode?.identifier == "ja"
                self.authBroadcastMessage = isJapanese
                    ? "現在ログインはご利用いただけません。しばらくしてからもう一度お試しください。"
                    : "Login is currently unavailable. Please try again later."
                self.isLoginAvailable = false
            }
        case .failed:
            break
        }
    }

    func refreshClientConfigIfNeeded() async {
        if client != nil,
           let lastFetch = UserDefaults.standard.object(forKey: remoteConfigFetchDateKey) as? Date,
           lastFetch.addingTimeInterval(remoteConfigFetchInterval) > .now {
            return
        }

        let provider = RemoteConfigProvider()
        guard await provider.accountStatus() == .available else { return }

        do {
            let config = try await provider.fetch()
            if let id = config.clientID,
               let secret = config.clientSecret,
               let redirectURL = config.redirectURL {
                let client = OpenIDClient(id: id, secret: secret, redirectURL: redirectURL)
                self.client = client
                cacheClientToKeychain(client)
            }
            UserDefaults.standard.set(Date.now, forKey: remoteConfigFetchDateKey)
        } catch {
            debugPrint("Remote config fetch failed: \(error.localizedDescription)")
        }
    }

    private func cacheClientToKeychain(_ client: OpenIDClient) {
        if let data = try? JSONEncoder().encode(client),
           let string = String(data: data, encoding: .utf8) {
            try? keychain.set(string, key: keychainClientKey)
        }
    }

    private func restoreClientFromKeychain() -> OpenIDClient? {
        if let string = try? keychain.get(keychainClientKey),
           let data = string.data(using: .utf8),
           let client = try? JSONDecoder().decode(OpenIDClient.self, from: data) {
            return client
        }
        return nil
    }

    func setupReachability() {
        if let reachability {
            reachability.whenReachable = { [weak self] _ in
                Task {
                    await self?.handleReachable()
                }
            }
            reachability.whenUnreachable = { [weak self] _ in
                Task {
                    self?.handleUnreachable()
                }
            }
            do {
                try reachability.startNotifier()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    private func handleReachable() async {
        self.onlineState = .online
        if !self.isReady {
            // Restore previous authentication token
            if !self.restoreAuthenticationFromKeychainAndDefaults() {
                self.resetAuthentication()
                self.isReady = true
            } else {
                // Refresh authentication token in the background if close to expiry
                if self.tokenExpiryDate.addingTimeInterval(-3600) < .now {
                    Task {
                        await self.refreshAuthenticationToken()
                    }
                }
                self.isReady = true
            }
        }
    }

    private func handleUnreachable() {
        self.onlineState = .offline
        self.useOfflineAuthenticationToken()
        if !self.isReady {
            self.isReady = true
        }
    }

    func restoreAuthenticationFromKeychainAndDefaults() -> Bool {
        // Returns Bool: Whether authentication is still fresh enough
        if let tokenExpiryDate = UserDefaults.standard.object(forKey: tokenExpiryDateKey) as? Date,
           tokenExpiryDate > .now,
           let tokenInKeychain = try? keychain.get(keychainAuthTokenKey),
           let tokenData = tokenInKeychain.data(using: .utf8),
           let token = try? JSONDecoder().decode(OpenIDToken.self, from: tokenData) {
            self.token = token
            self.tokenExpiryDate = tokenExpiryDate
            return true
        }
        return false
    }

    func resetAuthentication() {
        code = nil
        token = nil
        try? keychain.removeAll()
        UserDefaults.standard.removeObject(forKey: keychainAuthTokenKey)
        isAuthenticating = true
    }

    func getAuthenticationCode(from url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            var parameters: [String: String] = [:]
            for item in queryItems {
                if let value = item.value {
                    parameters[item.name] = value
                }
            }
            if let code = parameters["code"],
               let state = parameters["state"],
               state == "auth" {
                self.code = code
                self.isWaitingForAuthenticationCode = false
            }
        }
    }

    func getAuthenticationToken() async {
        let request = urlRequestForToken(parameters: [
            "grant_type": "authorization_code",
            "code": code ?? ""
        ])

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            let isSuccessful = decodeAuthenticationToken(data: data)
            if isSuccessful {
                self.isAuthenticating = false
            }
        } else {
            self.token = nil
            self.isAuthenticating = true
        }
    }

    func useOfflineAuthenticationToken() {
        self.token = OpenIDToken()
    }

    func refreshAuthenticationToken() async {
        if let refreshToken = token?.refreshToken {
            let request = urlRequestForToken(parameters: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ])

            if let (data, _) = try? await URLSession.shared.data(for: request) {
                _ = decodeAuthenticationToken(data: data)
            } else {
                self.isAuthenticating = true
            }
        } else {
            self.isAuthenticating = true
        }
    }

    func decodeAuthenticationToken(data: Data) -> Bool {
        if let token = try? JSONDecoder().decode(OpenIDToken.self, from: data) {
            self.token = token
            self.updateTokenExpiryDate(from: token)
            if let tokenEncoded = try? JSONEncoder().encode(token),
               let tokenString = String(data: tokenEncoded, encoding: .utf8) {
                try? keychain.set(tokenString, key: keychainAuthTokenKey)
            }
            return true
        } else {
            self.code = nil
            self.token = nil
            self.isAuthenticating = true
            return false
        }
    }

    func updateTokenExpiryDate(from token: OpenIDToken) {
        let expiresIn = max(0, (Int(token.expiresIn) ?? 0) - 3600)
        let tokenExpiryDate = Calendar.current.date(byAdding: .second, value: expiresIn, to: .now) ?? .distantFuture
        UserDefaults.standard.set(tokenExpiryDate, forKey: tokenExpiryDateKey)
        self.tokenExpiryDate = tokenExpiryDate
    }

    func urlRequestForToken(parameters: [String: String]) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAuthEndpoint)/OAuth2/Token")!

        var parameters: [String: String] = parameters
        parameters["client_id"] = client?.id
        parameters["client_secret"] = client?.secret

        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 2.0)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        return request
    }
}
