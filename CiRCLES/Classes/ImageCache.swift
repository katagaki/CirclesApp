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
class ImageCache {

    @ObservationIgnored let cacheURL: URL?
    @ObservationIgnored var images: [Int: Data] = [:]

    init() {
        cacheURL = documentsDirectoryURL?.appendingPathComponent("ImageCache", conformingTo: .folder)
        if let cacheURL {
            if !FileManager.default.fileExists(atPath: cacheURL.path()) {
                try? FileManager.default.createDirectory(
                    at: cacheURL, withIntermediateDirectories: true, attributes: nil
                )
            }
            if let imageURLs = try? FileManager.default.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) {
                for imageURL in imageURLs {
                    if let imageData = try? Data(contentsOf: imageURL),
                       let imageID = Int(imageURL.lastPathComponent) {
                        images[imageID] = imageData
                    }
                }
            }
        }
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

    @MainActor
    func download(id: Int, url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            var finalImage: UIImage?
            if let image = UIImage(data: data) {
                // PNG, JPEG
                saveImage(data, named: String(id))
                images[id] = data
                finalImage = image
            } else if let cgImage = try? WebPDecoder().decode(data, options: WebPDecoderOptions()) {
                // WebP
                let image = UIImage(cgImage: cgImage)
                var nonWebpData: Data?
                if let convertedData = image.pngData() {
                    nonWebpData = convertedData
                } else if let convertedData = image.jpegData(compressionQuality: 1.0) {
                    nonWebpData = convertedData
                }
                if let nonWebpData {
                    saveImage(nonWebpData, named: String(id))
                    images[id] = nonWebpData
                    finalImage = UIImage(cgImage: cgImage)
                }
            }
            if let finalImage {
                return finalImage
            } else {
                // Others (unsupported formats)
                let placeholderData = Data()
                saveImage(placeholderData, named: String(id))
                images[id] = data
                return nil
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    return nil
    }

    func saveImage(_ imageData: Data, named imageFilename: String) {
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
        if let cacheURL {
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
