//
//  OpenIDToken.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/14.
//

struct OpenIDToken: Codable, Equatable {
    let accessToken: String
    let tokenType: String
    let expiresIn: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
