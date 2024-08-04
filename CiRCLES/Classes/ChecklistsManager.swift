//
//  ChecklistsManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import Foundation

@Observable
@MainActor
class ChecklistsManager {
    var checklists: [Checklist.Response.ChecklistItem] = []

    func getChecklists(authToken: OpenIDToken) async {
        let request = urlRequestForReadersAPI(endpoint: "FavoriteCircles", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Checklists response length: \(data.count)")
            if let checklists = try? JSONDecoder().decode(Checklist.self, from: data) {
                debugPrint("Decoded checklists")
                self.checklists = checklists.response.list
            }
        }
    }

    func urlRequestForReadersAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/Readers/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
