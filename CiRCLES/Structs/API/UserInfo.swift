//
//  UserInfo.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

struct UserInfo: Codable {
    let status: String
    let response: Response

    struct Response: Codable {
        let pid: Int
        let r18: Int
        let nickname: String
    }

}
