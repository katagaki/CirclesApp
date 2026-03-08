//
//  ImageCache.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/09.
//

import Foundation
import SwiftUI
import UIKit
import WebP

@Observable
@MainActor
class ImageCache {

    @ObservationIgnored
    static let cacheURL: URL? = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)?
        .appendingPathComponent("ImageCache", conformingTo: .folder)

    @ObservationIgnored var images: [Int: Data] = [:]
    @ObservationIgnored var isLoaded: Bool = false

    init() {
        if let cacheURL = ImageCache.cacheURL,
           !FileManager.default.fileExists(atPath: cacheURL.path()) {
            try? FileManager.default.createDirectory(
                at: cacheURL, withIntermediateDirectories: true, attributes: nil
            )
        }
    }

    func loadFromDisk() async {
        guard !isLoaded else { return }
        guard let cacheURL = ImageCache.cacheURL else { return }
        let loadedImages: [Int: Data] = await Task.detached(priority: .userInitiated) {
            var result: [Int: Data] = [:]
            if let imageURLs = try? FileManager.default.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) {
                for imageURL in imageURLs {
                    if let imageData = try? Data(contentsOf: imageURL),
                       let imageID = Int(imageURL.lastPathComponent) {
                        result[imageID] = imageData
                    }
                }
            }
            return result
        }.value
        images = loadedImages
        isLoaded = true
    }

    func image(_ id: Int) -> (Bool, UIImage?) {
        if images.keys.contains(id) {
            if let image = images[id],
               let image = UIImage(data: image) {
                return (true, image)
            } else {
                return (true, nil)
            }
        } else {
            return (false, nil)
        }
    }

    func set(_ id: Int, data: Data) {
        images[id] = data
    }

    static func download(id: Int, url: URL) async -> (UIImage?, Data?) {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            var finalImage: UIImage?
            var finalData: Data?
            if let image = UIImage(data: data) {
                // PNG, JPEG
                ImageCache.saveImage(data, named: String(id))
                finalImage = image
                finalData = data
            } else if let image = try? WebPDecoder().decodeUIImage(from: data, options: WebPDecoderOptions()) {
                // WebP
                var nonWebpData: Data?
                if let convertedData = image.pngData() {
                    nonWebpData = convertedData
                } else if let convertedData = image.jpegData(compressionQuality: 1.0) {
                    nonWebpData = convertedData
                }
                if let nonWebpData {
                    ImageCache.saveImage(nonWebpData, named: String(id))
                    finalImage = image
                    finalData = nonWebpData
                }
            }
            if let finalImage {
                return (finalImage, finalData)
            } else {
                // Others (unsupported formats)
                let placeholderData = Data()
                ImageCache.saveImage(placeholderData, named: String(id))
                return (nil, data)
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    return (nil, nil)
    }

    static func saveImage(_ imageData: Data, named imageFilename: String) {
        do {
            if let cacheURL {
                let imageFileURL = cacheURL.appendingPathComponent(imageFilename)
                try imageData.write(to: imageFileURL)
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func clear() {
        if let cacheURL = ImageCache.cacheURL {
            for imageURL in (try? FileManager.default.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )) ?? [] {
                do {
                    try FileManager.default.removeItem(at: imageURL)
                } catch {
                    debugPrint(error.localizedDescription)
                }
            }
            images.removeAll()
        }
    }

}
