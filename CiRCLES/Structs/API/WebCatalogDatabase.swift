//
//  WebCatalogDatabase.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

import Foundation

// swiftlint:disable nesting
struct WebCatalogDatabase: Codable {
    let status: String
    let response: Response

    struct Response: Codable {
        let urls: [String: String]
        let hashes: [String: String]
        let updateDate: String

        enum CodingKeys: String, CodingKey {
            case urls = "url"
            case hashes = "md5"
            case updateDate = "updatedate"
        }

        func databaseForText(for mode: SQLiteMode = .sqlite3, using compression: CompressionMode = .zip) -> URL? {
            if let urlString = urls["textdb_\(mode.rawValue)\(compression.rawValue)_ssl"] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }

        func databaseFor211By300Images(using compression: CompressionMode = .zip) -> URL? {
            if let urlString = urls["imagedb1\(compression.rawValue)_ssl"] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }

        func databaseFor180By256Images(using compression: CompressionMode = .zip) -> URL? {
            if let urlString = urls["imagedb2\(compression.rawValue)_ssl"] {
                return URL(string: urlString)
            } else {
                return nil
            }
        }

        enum SQLiteMode: String {
            case sqlite2
            case sqlite3
        }

        enum CompressionMode: String {
            case zip = "_zip_url"
            case gzip = "_url"
        }
    }
}
// swiftlint:enable nesting
