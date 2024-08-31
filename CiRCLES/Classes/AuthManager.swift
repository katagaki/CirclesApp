//
//  AuthManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

import Foundation
import KeychainAccess

@Observable
@MainActor
class AuthManager {

    let keychain = Keychain(service: "com.tsubuzaki.CiRCLES")
    let keychainAuthTokenKey: String = "CircleMsAuthToken"

    var isAuthenticating: Bool = false

    var code: String?
    var token: OpenIDToken?

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

        // Read token from keychain
        if let tokenInKeychain = try? keychain.get(keychainAuthTokenKey),
           let token = try? JSONDecoder().decode(OpenIDToken.self,
                                                 from: tokenInKeychain.data(using: .utf8) ?? Data()) {
            self.token = token
        }
    }

    func resetAuthentication() {
        code = nil
        token = nil
        try? keychain.removeAll()
        debugPrint("Signed out and deleted authentication token from local device.")
    }

    func getAuthenticationCode(from url: URL) {
        debugPrint("Getting authentication code")
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
                        debugPrint("Authentication code length: \(code.count)")
                        self.code = code
                    }
                }
            }
        }
    }

    func getAuthenticationToken() async {
        debugPrint("Getting authentication token")
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

    func refreshAuthenticationToken() async {
        if let refreshToken = token?.refreshToken {
            debugPrint("Refreshing authentication token")
            let request = urlRequestForToken(parameters: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ])

            if let (data, _) = try? await URLSession.shared.data(for: request) {
                decodeAuthenticationToken(data: data)
            } else {
                self.token = nil
                self.isAuthenticating = true
            }
        } else {
            debugPrint("No refresh token to use!")
        }
    }

    // swiftlint:disable non_optional_string_data_conversion
    func decodeAuthenticationToken(data: Data) {
        debugPrint("Authentication token length: \(data.count)")
        if let token = try? JSONDecoder().decode(OpenIDToken.self, from: data) {
            debugPrint("Decoded authentication token")
            self.token = token
            if let tokenEncoded = try? JSONEncoder().encode(token),
               let tokenString = String(data: tokenEncoded, encoding: .utf8) {
                debugPrint("Saving authentication token to keychain")
                try? keychain.set(tokenString, key: keychainAuthTokenKey)
            }
        } else {
            self.code = nil
            self.token = nil
            self.isAuthenticating = true
        }
    }
    // swiftlint:enable non_optional_string_data_conversion

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
