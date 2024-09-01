//
//  Downloader.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/31.
//

import Foundation

class Downloader: NSObject, @unchecked Sendable, URLSessionDownloadDelegate {

    var progressCallback: ((Double) -> Void)?
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
        onBytesReceived: @escaping (Double) -> Void
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
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        progressCallback?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
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

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
        }
    }
}
