//
//  EventManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

@Observable
@MainActor
class EventManager: NSObject {

    var events: [WebCatalogEvent.Response.Event] = []
    var latestEventID: Int?
    var latestEventNo: Int?

    func getEvents(authToken: OpenIDToken) async {
        let request = urlRequestForWebCatalogAPI("GetEventList", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Web Catalog event list response length: \(data.count)")
            if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                debugPrint("Decoded event list")
                self.events = events.response.list
                self.latestEventID = events.response.latestEventID
                self.latestEventNo = events.response.latestEventNo
            }
        }
    }

    func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/WebCatalog/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
