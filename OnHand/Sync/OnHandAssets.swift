//
//  OnHandAssets.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/25.
//

import Foundation
import UIKit

enum OnHandAssets {

    private static let directoryName = "OnHandAssets"

    private static var directoryURL: URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = caches.appending(path: directoryName)
        if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func circleCutURL(for circleID: Int) -> URL? {
        existingURL(named: "cut-\(circleID).jpg")
    }

    static func mapURL(forKey mapKey: String) -> URL? {
        existingURL(named: "map-\(mapKey).jpg")
    }

    private static func existingURL(named name: String) -> URL? {
        guard let url = directoryURL?.appending(path: name) else { return nil }
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    static func unpack(_ bundle: OnHandAssetBundle) {
        guard let directoryURL else { return }
        try? FileManager.default.removeItem(at: directoryURL)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        for (circleID, data) in bundle.circleCuts {
            try? data.write(to: directoryURL.appending(path: "cut-\(circleID).jpg"), options: .atomic)
        }
        for (mapKey, data) in bundle.maps {
            try? data.write(to: directoryURL.appending(path: "map-\(mapKey).jpg"), options: .atomic)
        }
    }

    static func image(at url: URL?) -> UIImage? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
