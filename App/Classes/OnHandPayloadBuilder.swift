//
//  OnHandPayloadBuilder.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import Foundation
import AXiS
import RADiUS

@MainActor
enum OnHandPayloadBuilder {

    static func build(
        favorites: Favorites,
        database: Database,
        events: Events,
        visitedCircleIDs: Set<Int>
    ) async -> OnHandPayload? {
        guard let favoriteItems = favorites.items, !favoriteItems.isEmpty else { return nil }

        let eventNumber = events.activeEventNumber
        guard eventNumber > 0 else { return nil }

        let fetcher = DataFetcher(database: database.getTextDatabase())
        let circleIdentifiers = await fetcher.circles(forFavorites: favoriteItems)
        guard !circleIdentifiers.isEmpty else { return nil }

        let circles = database.circles(circleIdentifiers)
        let maps = database.maps()
        let colorsByWebCatalogID = favorites.wcIDMappedItems ?? [:]

        var mapNamesByBlockID: [Int: String] = [:]
        for blockID in Set(circles.map { $0.blockID }) {
            if let mapID = await fetcher.mapID(forBlock: blockID),
               let map = maps.first(where: { $0.id == mapID }) {
                mapNamesByBlockID[blockID] = map.name
            }
        }

        var itemsByCircleID: [Int: [OnHandBuyItem]] = [:]
        for entry in BuysDatabase.shared.entries(for: eventNumber) {
            itemsByCircleID[entry.circleID] = entry.items.map { item in
                OnHandBuyItem(
                    id: item.id,
                    name: item.name,
                    cost: item.cost,
                    statusValue: item.status.rawValue
                )
            }
        }

        let payloadFavorites: [OnHandFavorite] = circles.compactMap { circle in
            guard let spaceLabel = circle.spaceName() else { return nil }
            let webCatalogID = circle.extendedInformation?.webCatalogID ?? 0
            let color = colorsByWebCatalogID[webCatalogID]?.favorite.color ?? .uncolored
            return OnHandFavorite(
                id: circle.id,
                webCatalogID: webCatalogID,
                circleName: circle.circleName,
                spaceLabel: spaceLabel,
                hallName: mapNamesByBlockID[circle.blockID] ?? "",
                day: circle.day,
                colorValue: color.rawValue,
                isVisited: visitedCircleIDs.contains(circle.id),
                items: itemsByCircleID[circle.id] ?? []
            )
        }

        let calendar = calendarInEventTimeZone()
        let days: [OnHandDay] = database.dates().map { date in
            let components = calendar.dateComponents([.month, .day], from: date.date)
            return OnHandDay(
                id: date.id,
                month: components.month ?? 0,
                day: components.day ?? 0
            )
        }

        return OnHandPayload(
            eventNumber: eventNumber,
            eventName: database.events().first(where: { $0.eventNumber == eventNumber })?.name ?? "",
            generatedAt: .now,
            days: days,
            favorites: payloadFavorites.sorted { $0.spaceLabel < $1.spaceLabel }
        )
    }

    private static func calendarInEventTimeZone() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(identifier: "Asia/Tokyo") {
            calendar.timeZone = timeZone
        }
        return calendar
    }
}
