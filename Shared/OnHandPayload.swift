//
//  OnHandPayload.swift
//  CiRCLES
//
//  Shared between the iOS app and the OnHand watch app. Keep this file free of
//  framework dependencies so both targets can compile it directly.
//

import Foundation

enum OnHandMessage {
    static let payload = "OnHand.Payload"
    static let intent = "OnHand.Intent"
}

struct OnHandPayload: Codable, Sendable, Equatable {
    var eventNumber: Int
    var eventName: String
    var generatedAt: Date
    var days: [OnHandDay]
    var favorites: [OnHandFavorite]

    static let empty = OnHandPayload(
        eventNumber: 0,
        eventName: "",
        generatedAt: .distantPast,
        days: [],
        favorites: []
    )
}

struct OnHandDay: Codable, Sendable, Equatable, Identifiable, Hashable {
    var id: Int
    var month: Int
    var day: Int
}

struct OnHandFavorite: Codable, Sendable, Equatable, Identifiable, Hashable {
    var id: Int
    var webCatalogID: Int
    var circleName: String
    var spaceLabel: String
    var hallName: String
    var hallFilename: String
    var day: Int
    var colorValue: Int
    var isVisited: Bool
    var items: [OnHandBuyItem]
}

struct OnHandBuyItem: Codable, Sendable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var cost: Int
    var statusValue: Int
}

struct OnHandIntent: Codable, Sendable, Equatable {
    enum Kind: String, Codable, Sendable {
        case toggleVisited
        case cycleBuyItem
    }

    var kind: Kind
    var circleID: Int
    var itemID: String?
}
