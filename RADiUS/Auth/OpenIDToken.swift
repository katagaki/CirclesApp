//
//  OpenIDToken.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/14.
//

public struct OpenIDToken: Codable, Equatable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: String
    public let refreshToken: String

    public init() {
        self.accessToken = ""
        self.tokenType = ""
        self.expiresIn = ""
        self.refreshToken = ""
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
