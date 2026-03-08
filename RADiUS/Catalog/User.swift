//
//  User.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

public class User {
    public static func info(authToken: OpenIDToken) async -> UserInfo.Response? {
        let request = urlRequestForUserAPI(endpoint: "Info", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) {
            return userInfo.response
        }
        return nil
    }

    public static func events(authToken: OpenIDToken) async -> [UserCircle.Response.Circle] {
        let request = urlRequestForUserAPI(endpoint: "Circles", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let userCircles = try? JSONDecoder().decode(UserCircle.self, from: data) {
            return userCircles.response.circles
        }
        return []
    }

    public static func urlRequestForUserAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/User/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
