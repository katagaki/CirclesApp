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

    var textDatabaseURL: URL?
    var imageDatabaseURL: URL?

    func getEvents(authToken: OpenIDToken) async {
        let request = urlRequestForWebCatalogAPI("GetEventList", type: .webCatalog, authToken: authToken)

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

    func getDatabases(for event: WebCatalogEvent.Response.Event, authToken: OpenIDToken) async {
        var request = urlRequestForWebCatalogAPI("All", type: .catalogBase, authToken: authToken)
        var parameters: [String: String] = [
            "event_id": String(event.id),
            "event_no": String(event.number)
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Web Catalog databases response length: \(data.count)")
            if let databases = try? JSONDecoder().decode(WebCatalogDatabase.self, from: data) {
                debugPrint("Decoded databases")
                self.textDatabaseURL = databases.response.databaseForText()
                self.imageDatabaseURL = databases.response.databaseFor211By300Images()
            }
        }
    }

    func urlRequestForWebCatalogAPI(_ endpoint: String, type: WebCatalogAPIType, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/\(type.rawValue)/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    enum WebCatalogAPIType: String {
        case webCatalog = "WebCatalog"
        case catalogBase = "CatalogBase"
    }
}
