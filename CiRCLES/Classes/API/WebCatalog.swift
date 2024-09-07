//
//  WebCatalog.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

class WebCatalog {

    static let eventCacheKey = "WebCatalog.Events"

    static func events(authToken: OpenIDToken) async -> WebCatalogEvent.Response? {
        let request = urlRequestForWebCatalogAPI(endpoint: "GetEventList", authToken: authToken)
        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Web Catalog event list response length: \(data.count)")
            if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                debugPrint("Decoded event list")
                UserDefaults.standard.set(data, forKey: eventCacheKey)
                return events.response
            }
        }
        if let data = UserDefaults.standard.data(forKey: eventCacheKey) {
            if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                debugPrint("Decoded event list from cache")
                return events.response
            }
        }
        return nil
    }

    // TODO: Figure out a smart way to split UserFavorite and circle details
    static func circle(with webCatalogID: Int, authToken: OpenIDToken) async -> UserFavorite? {
        let request = urlRequestForWebCatalogAPI(
            endpoint: "GetCircle",
            method: "GET",
            parameters: [
                "wcid": String(webCatalogID)
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

    static func urlRequestForWebCatalogAPI(
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
