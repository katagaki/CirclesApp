//
//  OpenIDClient.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/09.
//

public struct OpenIDClient: Codable, Sendable {
    public let id: String
    public let secret: String
    public let redirectURL: String

    enum CodingKeys: String, CodingKey {
        case id = "client_id"
        case secret = "client_secret"
        case redirectURL = "redirect_url"
    }

    public init(id: String, secret: String, redirectURL: String) {
        self.id = id
        self.secret = secret
        self.redirectURL = redirectURL
    }
}
