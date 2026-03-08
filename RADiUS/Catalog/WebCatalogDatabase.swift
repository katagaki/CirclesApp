//
//  WebCatalogDatabase.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

// swiftlint:disable nesting
public struct WebCatalogDatabase: Codable, Sendable {
    public let status: String
    public let response: Response

    public struct Response: Codable, Sendable {
        public let urls: [String: String]
        public let hashes: [String: String]
        public let updateDate: String

        enum CodingKeys: String, CodingKey {
            case urls = "url"
            case hashes = "md5"
            case updateDate = "updatedate"
        }

        public func databaseForText(for mode: SQLiteMode = .sqlite3, using compression: CompressionMode = .zip) -> URL? {
            if let urlString = urls["textdb_\(mode.rawValue)\(compression.rawValue)_ssl"] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }

        public func databaseFor211By300Images(using compression: CompressionMode = .zip) -> URL? {
            if let urlString = urls["imagedb1\(compression.rawValue)_ssl"] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }

        public func databaseFor180By256Images(using compression: CompressionMode = .zip) -> URL? {
            if let urlString = urls["imagedb2\(compression.rawValue)_ssl"] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }

        public enum SQLiteMode: String {
            case sqlite2
            case sqlite3
        }

        public enum CompressionMode: String {
            case zip = "_zip_url"
            case gzip = "_url"
        }
    }
}
// swiftlint:enable nesting
