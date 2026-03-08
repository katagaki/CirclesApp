//
//  UserCircle.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

// swiftlint:disable nesting
public struct UserCircle: Codable, Sendable {
    public let status: String
    public let response: Response

    public struct Response: Codable, Sendable {
        public let count: Int
        public let circles: [Circle]

        public struct Circle: Codable, Sendable {
            public let eventID: Int
            public let webCatalogID: Int
            public let circleMsID: Int
            public let name: String

            enum CodingKeys: String, CodingKey {
                case eventID = "EventId"
                case webCatalogID = "wcid"
                case circleMsID = "circlemsId"
                case name = "name"
            }
        }
    }
}
// swiftlint:enable nesting
