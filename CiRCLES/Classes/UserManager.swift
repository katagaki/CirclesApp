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
    var userInfo: UserInfo.Response?

    func getUser(authToken: OpenIDToken) async {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/User/Info/")!
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        debugPrint(authToken.accessToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("User info response length: \(data.count)")
            debugPrint(String(data: data, encoding: .utf8))
            try! JSONDecoder().decode(UserInfo.self, from: data)
            if let userInfo = try? JSONDecoder().decode(UserInfo.self, from: data) {
                debugPrint("Decoded user info")
                self.userInfo = userInfo.response
            }
        }
    }

}
