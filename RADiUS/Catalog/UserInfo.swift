//
//  UserInfo.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

public struct UserInfo: Codable, Sendable {
    public let status: String
    public let response: Response

    public struct Response: Codable, Sendable {
        public let pid: Int
        public let r18: Int
        public let nickname: String
    }
}
