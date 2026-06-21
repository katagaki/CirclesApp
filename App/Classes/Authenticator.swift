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
        guard let reachability else {
            bootstrap(isConnected: false)
            return
        }
        reachability.whenReachable = { [weak self] _ in
            Task { await self?.handleReachable() }
        }
        reachability.whenUnreachable = { [weak self] _ in
            Task { self?.handleUnreachable() }
        }
        do {
            try reachability.startNotifier()
            // The notifier normally fires an initial callback that calls bootstrap,
            // but if it never does the app would hang on the loading screen forever.
            // Fall back to a connectivity-agnostic bootstrap after a short grace period.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(3))
                guard let self, !self.isReady else { return }
                self.bootstrap(isConnected: self.onlineState == .online)
            }
        } catch {
            debugPrint(error.localizedDescription)
            bootstrap(isConnected: false)
        }
    }

    func bootstrap(isConnected: Bool) {
        guard !isReady else { return }
        onlineState = isConnected ? .online : .offline

        if restoreAuthenticationFromKeychainAndDefaults() {
            if isConnected && tokenExpiryDate.addingTimeInterval(-3600) < .now {
                Task { await refreshAuthenticationToken() }
            }
        } else if !isConnected {
            if let storedToken = loadStoredToken(), !storedToken.accessToken.isEmpty {
                token = storedToken
                tokenExpiryDate = (UserDefaults.standard.object(forKey: tokenExpiryDateKey) as? Date) ?? .distantPast
            } else {
                useOfflineAuthenticationToken()
            }
        } else {
            resetAuthentication()
        }

        isReady = true
    }

    private func handleReachable() async {
        onlineState = .online
        if !isReady {
            bootstrap(isConnected: true)
            return
        }
        if let token, !token.accessToken.isEmpty,
           tokenExpiryDate.addingTimeInterval(-3600) < .now {
            await refreshAuthenticationToken()
        }
    }

    private func handleUnreachable() {
        onlineState = .offline
        if !isReady {
            bootstrap(isConnected: false)
            return
        }
        useOfflineAuthenticationToken()
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

    func loadStoredToken() -> OpenIDToken? {
        if let tokenInKeychain = try? keychain.get(keychainAuthTokenKey),
           let tokenData = tokenInKeychain.data(using: .utf8),
           let token = try? JSONDecoder().decode(OpenIDToken.self, from: tokenData) {
            return token
        }
        return nil
    }

    func resetAuthentication() {
        code = nil
        token = nil
        try? keychain.remove(keychainAuthTokenKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiryDateKey)
        tokenExpiryDate = .distantFuture
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

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if decodeAuthenticationToken(data: data) {
                self.isAuthenticating = false
            } else {
                self.code = nil
                self.token = nil
                self.isAuthenticating = true
            }
        } catch {
            self.isAuthenticating = true
        }
    }

    func useOfflineAuthenticationToken() {
        if token == nil {
            self.token = OpenIDToken()
        }
    }

    func refreshAuthenticationToken() async {
        guard let refreshToken = token?.refreshToken, !refreshToken.isEmpty else {
            if onlineState == .online {
                self.isAuthenticating = true
            }
            return
        }

        let request = urlRequestForToken(parameters: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               (400..<500).contains(httpResponse.statusCode) {
                resetAuthentication()
                return
            }
            _ = decodeAuthenticationToken(data: data)
        } catch {
            // Transient failure (timeout, offline, captive portal): keep the existing
            // token and retry later rather than forcing re-login. Only a decisive 4xx
            // (handled above) clears authentication.
        }
    }

    func refreshAuthenticationTokenInBackground() async {
        if token == nil {
            token = loadStoredToken()
            if let storedExpiry = UserDefaults.standard.object(forKey: tokenExpiryDateKey) as? Date {
                tokenExpiryDate = storedExpiry
            }
        }
        if tokenExpiryDate.addingTimeInterval(-3600) > .now {
            return
        }
        guard let refreshToken = token?.refreshToken, !refreshToken.isEmpty else { return }
        let request = urlRequestForToken(parameters: [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ], timeoutInterval: 10.0)
        if let (data, response) = try? await URLSession.shared.data(for: request) {
            if let httpResponse = response as? HTTPURLResponse,
               (400..<500).contains(httpResponse.statusCode) {
                return
            }
            _ = decodeAuthenticationToken(data: data)
        }
    }

    @discardableResult
    func decodeAuthenticationToken(data: Data) -> Bool {
        guard let token = try? JSONDecoder().decode(OpenIDToken.self, from: data) else {
            return false
        }
        self.token = token
        self.updateTokenExpiryDate(from: token)
        if let tokenEncoded = try? JSONEncoder().encode(token),
           let tokenString = String(data: tokenEncoded, encoding: .utf8) {
            try? keychain.set(tokenString, key: keychainAuthTokenKey)
        }
        return true
    }

    func updateTokenExpiryDate(from token: OpenIDToken) {
        let expiresIn = max(0, (Int(token.expiresIn) ?? 0) - 3600)
        let tokenExpiryDate = Calendar.current.date(byAdding: .second, value: expiresIn, to: .now) ?? .distantFuture
        UserDefaults.standard.set(tokenExpiryDate, forKey: tokenExpiryDateKey)
        self.tokenExpiryDate = tokenExpiryDate
    }

    func urlRequestForToken(parameters: [String: String], timeoutInterval: TimeInterval = circleMsTokenTimeout) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAuthEndpoint)/OAuth2/Token")!

        var parameters: [String: String] = parameters
        parameters["client_id"] = client?.id
        parameters["client_secret"] = client?.secret

        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: timeoutInterval
        )
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        return request
    }
}
