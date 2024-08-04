//
//  UserManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

@Observable
@MainActor
class UserManager {
    var info: UserInfo.Response?
    var circles: [UserCircle.Response.Circle] = []

    func getUser(authToken: OpenIDToken) async {
        let request = urlRequestForUserAPI(endpoint: "Info", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("User info response length: \(data.count)")
            if let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) {
                debugPrint("Decoded user info")
                self.info = userInfo.response
            }
        }
    }

    func getEvents(authToken: OpenIDToken) async {
        let request = urlRequestForUserAPI(endpoint: "Circles", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("User info response length: \(data.count)")
            if let userCircles = try? JSONDecoder().decode(UserCircle.self, from: data) {
                debugPrint("Decoded user circles")
                self.circles = userCircles.response.circles
            }
        }
    }

    func urlRequestForUserAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/User/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
