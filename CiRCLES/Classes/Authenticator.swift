//
//  Authenticator.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

import Foundation
import KeychainAccess
import Reachability

@Observable
@MainActor
class Authenticator {

    @ObservationIgnored let keychain = Keychain(service: "com.tsubuzaki.CiRCLES")
    @ObservationIgnored let keychainAuthTokenKey: String = "CircleMsAuthToken"
    @ObservationIgnored let tokenExpiryDateKey: String = "Auth.TokenExpiryDate"
    @ObservationIgnored let reachability = try? Reachability()

    var isAuthenticating: Bool = false
    var isWaitingForAuthenticationCode: Bool = false
    var onlineState: OnlineState = .undetermined

    var code: String?
    var token: OpenIDToken?
    var tokenExpiryDate: Date = .distantFuture

    @ObservationIgnored let client: OpenIDClient

    var authURL: URL {
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

        return (components?.url)!
    }

    init() {
        // Read OpenID information from OpenID.plist
        let url = Bundle.main.url(forResource: "OpenID", withExtension: "plist")!
        do {
            let data = try Data(contentsOf: url)
            let result = try PropertyListDecoder().decode(OpenIDClient.self, from: data)
            self.client = result
        } catch {
            fatalError("OpenID client initialization failed. Did you set up your OpenID.plist file yet?")
        }

        // Set up Internet connectivity tracking
        if let reachability {
            reachability.whenReachable = { _ in
                self.onlineState = .online
            }
            reachability.whenUnreachable = { _ in
                self.onlineState = .offline
            }
            do {
                try reachability.startNotifier()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }

        // Restore previous authentication token
        if !restoreAuthenticationFromKeychainAndDefaults() {
            self.resetAuthentication()
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
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let queryItems = components.queryItems {
                var parameters: [String: String] = [:]
                for item in queryItems {
                    if let value = item.value {
                        parameters[item.name] = value
                    }
                }
                if let code = parameters["code"],
                    let state = parameters ["state"] {
                    if state == "auth" {
                        self.code = code
                        self.isAuthenticating = false
                    }
                }
            }
        }
    }

    func getAuthenticationToken() async {
        let request = urlRequestForToken(parameters: [
            "grant_type": "authorization_code",
            "code": code ?? ""
        ])

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            decodeAuthenticationToken(data: data)
        } else {
            self.token = nil
            self.isAuthenticating = true
        }
    }

    func useOfflineAuthenticationToken() {
        self.token = nil
    }

    func refreshAuthenticationToken() async {
        if let refreshToken = token?.refreshToken {
            let request = urlRequestForToken(parameters: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ])

            if let (data, _) = try? await URLSession.shared.data(for: request) {
                decodeAuthenticationToken(data: data)
            } else {
                self.isAuthenticating = true
            }
        } else {
            self.isAuthenticating = true
        }
    }

    func decodeAuthenticationToken(data: Data) {
        if let token = try? JSONDecoder().decode(OpenIDToken.self, from: data) {
            self.token = token
            self.updateTokenExpiryDate(from: token)
            if let tokenEncoded = try? JSONEncoder().encode(token),
               let tokenString = String(data: tokenEncoded, encoding: .utf8) {
                try? keychain.set(tokenString, key: keychainAuthTokenKey)
            }
        } else {
            self.code = nil
            self.token = nil
            self.isAuthenticating = true
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
        parameters["client_id"] = client.id
        parameters["client_secret"] = client.secret

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        return request
    }
}
