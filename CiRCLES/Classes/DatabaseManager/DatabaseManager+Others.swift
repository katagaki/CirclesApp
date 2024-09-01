//
//  DatabaseManager+Others.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import ZIPFoundation

extension DatabaseManager {

    func download(_ url: URL?) async -> URL? {
        if let url = url, let documentsDirectoryURL {
            do {
                debugPrint("Downloading \(url.path())")
                let downloader: Downloader = Downloader()
                return try await downloader.download(from: url, to: documentsDirectoryURL) { progress in
                    self.downloadProgress = progress
                }
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    func unzip(_ url: URL?) -> URL? {
        if let url, let documentsDirectoryURL {
            do {
                debugPrint("Unzipping \(url.path())")
                let unzipDestinationURL = documentsDirectoryURL
                try? FileManager.default.removeItem(at: unzipDestinationURL
                    .appendingPathComponent(url.deletingPathExtension().lastPathComponent))
                try FileManager.default.unzipItem(at: url, to: unzipDestinationURL)
                if let archive = try? Archive(url: url, accessMode: .read, pathEncoding: .utf8) {
                    if let firstFileInArchive = archive.first(where: { _ in return true }) {
                        try? FileManager.default.removeItem(at: url)
                        return unzipDestinationURL.appending(path: firstFileInArchive.path)
                    }
                }
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    func urlRequestForWebCatalogAPI(_ endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/CatalogBase/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
