//
//  AuthManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

import Foundation

@Observable
class AuthManager {

    var code: String? = nil
    
    @ObservationIgnored let client: OpenIDClient

    var authURL: URL {
        let baseURL = circlesAuthEndpoint.appending(path: "OAuth2")
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
        let url = Bundle.main.url(forResource: "OpenID", withExtension:"plist")!
        do {
            let data = try Data(contentsOf: url)
            let result = try PropertyListDecoder().decode(OpenIDClient.self, from: data)
            self.client = result
        } catch {
            fatalError("OpenID client initialization failed. Did you set up your OpenID.plist file yet?")
        }
    }

    func completeAuthentication(from url: URL) {
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
                    }
                }
            }
        }
    }
}
