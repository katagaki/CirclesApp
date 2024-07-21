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

    let defaults = UserDefaults.standard
    let eventsKey = "Events.List"
    let latestEventIDKey = "Events.LatestEventID"
    let latestEventNumberKey = "Events.LatestEventNumber"

    var events: [WebCatalogEvent.Response.Event]?
    var latestEventID: Int?
    var latestEventNumber: Int?

    override init() {
        if let encodedEventsData = defaults.data(forKey: eventsKey),
           let decodedEvents = try? JSONDecoder().decode([WebCatalogEvent.Response.Event].self,
                                                         from: encodedEventsData) {
            self.events = decodedEvents
        }
        self.latestEventID = defaults.object(forKey: latestEventIDKey) as? Int
        self.latestEventNumber = defaults.object(forKey: latestEventNumberKey) as? Int
    }

    func latestEvent() -> WebCatalogEvent.Response.Event? {
        return events?.first(where: {$0.id == latestEventID && $0.number == latestEventNumber})
    }

    func getEvents(authToken: OpenIDToken) async {
        if events == nil || latestEventID == nil || latestEventNumber == nil {
            let request = urlRequestForWebCatalogAPI("GetEventList", authToken: authToken)

            if let (data, _) = try? await URLSession.shared.data(for: request) {
                debugPrint("Web Catalog event list response length: \(data.count)")
                if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                    debugPrint("Decoded event list")
                    self.events = events.response.list
                    self.latestEventID = events.response.latestEventID
                    self.latestEventNumber = events.response.latestEventNo
                }
            }
            if let encodedEvents = try? JSONEncoder().encode(self.events) {
                defaults.set(encodedEvents, forKey: eventsKey)
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
