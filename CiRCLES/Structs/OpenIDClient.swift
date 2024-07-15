//
//  OpenIDClient.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/09.
//

struct OpenIDClient: Decodable {
    let id: String
    let secret: String
    let redirectURL: String

    enum CodingKeys: String, CodingKey {
        case id = "client_id"
        case secret = "client_secret"
        case redirectURL = "redirect_url"
    }
}
