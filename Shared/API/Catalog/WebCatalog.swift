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
            if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                UserDefaults.standard.set(data, forKey: eventCacheKey)
                return events.response
            }
        }
        if let data = UserDefaults.standard.data(forKey: eventCacheKey) {
            if let events = try? JSONDecoder().decode(WebCatalogEvent.self, from: data) {
                return events.response
            }
        }
        return nil
    }

    static func circle(with webCatalogID: Int, authToken: OpenIDToken) async -> UserCircleWithFavorite? {
        let request = urlRequestForWebCatalogAPI(
            endpoint: "GetCircle",
            method: "GET",
            parameters: [
                "wcid": String(webCatalogID)
            ],
            authToken: authToken
        )
        if let (data, _) = try? await URLSession.shared.data(for: request) {
            if let circle = try? JSONDecoder().decode(UserCircleWithFavorite.self, from: data) {
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
            var request = URLRequest(url: endpoint, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 2.0)
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")
            return request
        } else {
            fatalError("Fatal error when trying to get URL request for WebCatalog API")
        }
    }
}
