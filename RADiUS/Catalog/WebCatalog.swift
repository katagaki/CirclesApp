//
//  WebCatalog.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

public class WebCatalog {

    public static let eventCacheKey = "WebCatalog.Events"

    public static func events(authToken: OpenIDToken) async -> WebCatalogEvent.Response? {
        return await refreshedEvents(authToken: authToken) ?? cachedEvents()
    }

    /// Fetches the event list from the API, bypassing the local URL cache so that newly added events
    /// are always picked up. Returns `nil` when the request fails, letting callers tell a successful
    /// refresh apart from a fallback to previously stored data.
    public static func refreshedEvents(authToken: OpenIDToken) async -> WebCatalogEvent.Response? {
        let request = urlRequestForWebCatalogAPI(
            endpoint: "GetEventList",
            cachePolicy: .reloadIgnoringLocalCacheData,
            authToken: authToken
        )
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
            UserDefaults.standard.set(data, forKey: eventCacheKey)
            return events.response
        }
        return nil
    }

    public static func cachedEvents() -> WebCatalogEvent.Response? {
        if let data = UserDefaults.standard.data(forKey: eventCacheKey),
           let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
            return events.response
        }
        return nil
    }

    public static func circle(with webCatalogID: Int, authToken: OpenIDToken) async -> UserCircleWithFavorite? {
        let request = urlRequestForWebCatalogAPI(
            endpoint: "GetCircle",
            method: "GET",
            parameters: [
                "wcid": String(webCatalogID)
            ],
            authToken: authToken
        )
        if let (data, _) = try? await URLSession.shared.data(for: request),
           let circle = try? JSONDecoder().decode(UserCircleWithFavorite.self, from: data) {
            return circle
        }
        return nil
    }

    public static func urlRequestForWebCatalogAPI(
        endpoint: String,
        method _: String = "POST",
        parameters: [String: String] = [:],
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad,
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
            var request = URLRequest(
                url: endpoint,
                cachePolicy: cachePolicy,
                timeoutInterval: circleMsAPITimeout
            )
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")
            return request
        } else {
            fatalError("Fatal error when trying to get URL request for WebCatalog API")
        }
    }
}
