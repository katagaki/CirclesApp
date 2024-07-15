//
//  EventManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

@Observable
@MainActor
class EventManager {
    var events: [WebCatalogEvent.Response.Event] = []
    var latestEventId: Int?
    var latestEventNo: Int?

    func getEvents(authToken: OpenIDToken) async {
        let request = urlRequestForWebCatalogAPI(endpoint: "GetEventList", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Web Catalog event list response length: \(data.count)")
            if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                debugPrint("Decoded event list")
                self.events = events.response.list
                self.latestEventId = events.response.latestEventId
                self.latestEventNo = events.response.latestEventNo
            }
        }
    }

    func urlRequestForWebCatalogAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/WebCatalog/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
