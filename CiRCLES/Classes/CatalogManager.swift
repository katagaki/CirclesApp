//
//  CatalogManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

@Observable
class CatalogManager: NSObject {

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

    @MainActor
    func getEvents(authToken: OpenIDToken) async {
        if events == nil || latestEventID == nil || latestEventNumber == nil {
            let request = urlRequestForWebCatalogAPI(endpoint: "GetEventList", authToken: authToken)
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

    @MainActor
    // TODO: Figure out a smart way to split UserFavorite and circle details
    func getCircle(
        _ circle: ComiketCircle,
        using extendedInformation: ComiketCircleExtendedInformation,
        authToken: OpenIDToken
    ) async -> UserFavorite? {
        let request = urlRequestForWebCatalogAPI(
            endpoint: "GetCircle",
            method: "GET",
            parameters: [
                "wcid": String(extendedInformation.webCatalogID)
            ],
            authToken: authToken
        )
        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Web Catalog circle response length: \(data.count)")
            if let circle = try? JSONDecoder().decode(UserFavorite.self, from: data) {
                debugPrint("Decoded circle")
                return circle
            }
        }
        return nil
    }

    func urlRequestForWebCatalogAPI(
        endpoint: String,
        method: String = "POST",
        parameters: [String: String] = [:],
        authToken: OpenIDToken
    ) -> URLRequest {
        var endpointComponents = URLComponents(string: "\(circleMsAPIEndpoint)/WebCatalog/\(endpoint)")!

        if parameters.keys.count > 0 {
            var queryItems: [URLQueryItem] = []
            for (key, value) in parameters {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            endpointComponents.queryItems = queryItems
        }

        if let endpoint = endpointComponents.url {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")
            return request
        } else {
            fatalError("Fatal error when trying to get URL request for WebCatalog API")
        }
    }
}
