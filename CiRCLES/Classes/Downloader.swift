//
//  Downloader.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/31.
//

import Foundation

class Downloader: NSObject, @unchecked Sendable, URLSessionDownloadDelegate {

    var progressCallback: ((Double) async -> Void)?
    var continuation: CheckedContinuation<URL, Error>?
    var session: URLSession?
    var destinationURL: URL?

    override init() {
        super.init()
        self.session = URLSession(
            configuration: .background(withIdentifier: "com.tsubuzaki.CiRCLES.Downloader.\(UUID().uuidString)"),
            delegate: self,
            delegateQueue: .main
        )
    }

    @MainActor
    func download(
        from sourceURL: URL,
        to destinationURL: URL,
        onBytesReceived: @escaping (Double) async -> Void
    ) async throws -> URL {
        self.progressCallback = onBytesReceived
        self.destinationURL = destinationURL
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let downloadRequest = URLRequest(url: sourceURL)
            let downloadTask = session?.downloadTask(with: downloadRequest)
            downloadTask?.resume()
        }
    }

    func urlSession(
        _ session: URLSession, // swiftlint:disable:this unused_parameter
        downloadTask _: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task {
            await progressCallback?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        }
    }

    func urlSession(_ session: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) { // swiftlint:disable:this unused_parameter
        if let destinationURL {
            do {
                let saveDestinationURL = destinationURL.appending(path: location.lastPathComponent)
                try? FileManager.default.removeItem(at: saveDestinationURL)
                try FileManager.default.moveItem(at: location, to: saveDestinationURL)
                continuation?.resume(returning: saveDestinationURL)
            } catch {
                continuation?.resume(throwing: error)
            }
        } else {
            continuation?.resume(returning: location)
        }
    }

    func urlSession(_ session: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) { // swiftlint:disable:this unused_parameter
        if let error {
            continuation?.resume(throwing: error)
        }
    }
}
