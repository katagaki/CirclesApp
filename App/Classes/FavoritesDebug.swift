//
//  FavoritesDebug.swift
//  CiRCLES
//
//  Created by Claude on 2026/08/14.
//

import Foundation
import RADiUS

// Captures raw favorite responses so that color codes can be inspected before
// WebCatalogColor's decoder coerces unrecognized values to .uncolored.

enum FavoritesDebugSource: String, Sendable {
    case network = "Network"
    case cache = "Cache"
}

struct FavoritesDebugEntry: Identifiable, Sendable {
    let id = UUID()
    let webCatalogID: Int?
    let circleName: String
    // Straight out of the JSON, never passed through WebCatalogColor.
    let rawColor: Int?

    // What WebCatalogColor resolves the raw value to, nil when unmapped.
    var mappedColor: WebCatalogColor? {
        guard let rawColor else { return nil }
        return WebCatalogColor(rawValue: rawColor)
    }

    var isUnmapped: Bool {
        rawColor != nil && mappedColor == nil
    }
}

struct FavoritesDebugCapture: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let source: FavoritesDebugSource
    let byteCount: Int
    let status: String?
    let entries: [FavoritesDebugEntry]
    let rawJSON: String?
    let note: String?

    var unmappedCodes: [Int: Int] {
        entries.reduce(into: [Int: Int]()) { partialResult, entry in
            if entry.isUnmapped, let rawColor = entry.rawColor {
                partialResult[rawColor, default: 0] += 1
            }
        }
    }

    var colorCodeCounts: [Int: Int] {
        entries.reduce(into: [Int: Int]()) { partialResult, entry in
            if let rawColor = entry.rawColor {
                partialResult[rawColor, default: 0] += 1
            }
        }
    }

    // Pulls color codes out of the JSON directly, so unrecognized values stay
    // visible instead of collapsing into .uncolored.
    static func capture(from data: Data, source: FavoritesDebugSource) -> FavoritesDebugCapture {
        var entries: [FavoritesDebugEntry] = []
        var status: String?

        let json = try? JSONSerialization.jsonObject(with: data)
        if let root = json as? [String: Any] {
            status = root["status"] as? String
            if let response = root["response"] as? [String: Any],
               let list = response["list"] as? [[String: Any]] {
                for item in list {
                    let favorite = item["favorite"] as? [String: Any]
                    let circle = item["circle"] as? [String: Any]
                    entries.append(
                        FavoritesDebugEntry(
                            webCatalogID: favorite?["wcid"] as? Int ?? circle?["wcid"] as? Int,
                            circleName: favorite?["circle_name"] as? String
                                ?? circle?["name"] as? String
                                ?? "-",
                            rawColor: favorite?["color"] as? Int
                        )
                    )
                }
            }
        }

        return FavoritesDebugCapture(
            date: .now,
            source: source,
            byteCount: data.count,
            status: status,
            entries: entries,
            rawJSON: prettyPrinted(data),
            note: json == nil ? "Response was not valid JSON." : nil
        )
    }

    static func capture(
        from favoriteItems: [UserFavorites.Response.FavoriteItem],
        source: FavoritesDebugSource,
        note: String?
    ) -> FavoritesDebugCapture {
        FavoritesDebugCapture(
            date: .now,
            source: source,
            byteCount: 0,
            status: nil,
            entries: favoriteItems.map { favoriteItem in
                FavoritesDebugEntry(
                    webCatalogID: favoriteItem.circle.webCatalogID,
                    circleName: favoriteItem.favorite.circleName,
                    rawColor: favoriteItem.favorite.color.rawValue
                )
            },
            rawJSON: nil,
            note: note
        )
    }

    static func prettyPrinted(_ data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
           ),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes, not UTF-8>"
    }
}

@MainActor
@Observable
final class FavoritesDebug {

    static let shared = FavoritesDebug()

    private(set) var captures: [FavoritesDebugCapture] = []

    // Captures hold the full response body, so keep only a short history.
    private let captureLimit: Int = 5

    func record(_ capture: FavoritesDebugCapture) {
        captures.insert(capture, at: 0)
        if captures.count > captureLimit {
            captures.removeLast(captures.count - captureLimit)
        }
    }

    func clear() {
        captures.removeAll()
    }
}
