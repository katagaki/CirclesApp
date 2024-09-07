//
//  User.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

class User {
    static func info(authToken: OpenIDToken) async -> UserInfo.Response? {
        let request = urlRequestForUserAPI(endpoint: "Info", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("User info response length: \(data.count)")
            if let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) {
                debugPrint("Decoded user info")
                return userInfo.response
            }
        }
        return nil
    }

    static func events(authToken: OpenIDToken) async -> [UserCircle.Response.Circle] {
        let request = urlRequestForUserAPI(endpoint: "Circles", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("User info response length: \(data.count)")
            if let userCircles = try? JSONDecoder().decode(UserCircle.self, from: data) {
                debugPrint("Decoded user circles")
                return userCircles.response.circles
            }
        }
        return []
    }

    static func urlRequestForUserAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/User/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
