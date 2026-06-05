//
//  RemoteConfig.swift
//  CiRCLES
//
//  Created by Claude on 2026/06/05.
//

import CloudKit
import Foundation

struct RemoteConfig: Sendable {
    var clientID: String?
    var clientSecret: String?
    var redirectURL: String?
    var broadcastMessage: String?
}

enum BroadcastFetchOutcome: Sendable {
    case found(message: String?, authEnabled: Bool)
    case notFound
    case failed
}

actor RemoteConfigProvider {

    static let containerIdentifier: String = "iCloud.com.tsubuzaki.KamiSeries"
    static let recordType: String = "RemoteConfig"
    static let recordName: String = "production"

    private let container: CKContainer
    private let database: CKDatabase

    init() {
        let container = CKContainer(identifier: Self.containerIdentifier)
        self.container = container
        self.database = container.publicCloudDatabase
    }

    func accountStatus() async -> CKAccountStatus {
        (try? await container.accountStatus()) ?? .couldNotDetermine
    }

    func fetch() async throws -> RemoteConfig {
        let recordID = CKRecord.ID(recordName: Self.recordName)
        let record = try await database.record(for: recordID)
        return RemoteConfig(
            clientID: record["clientID"] as? String,
            clientSecret: record["clientSecret"] as? String,
            redirectURL: record["redirectURL"] as? String,
            broadcastMessage: Self.broadcastMessage(from: record)
        )
    }

    func fetchBroadcastMessage(timeout: TimeInterval = 5.0) async -> BroadcastFetchOutcome {
        let recordID = CKRecord.ID(recordName: Self.recordName)
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        operation.desiredKeys = ["authMessage", "authMessageJa", "authMessageActive", "authEnabled"]
        let configuration = CKOperation.Configuration()
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        operation.configuration = configuration

        return await withCheckedContinuation { continuation in
            var message: String?
            var authEnabled = true
            var recordFound = false
            var recordMissing = false
            operation.perRecordResultBlock = { _, result in
                switch result {
                case .success(let record):
                    recordFound = true
                    message = Self.broadcastMessage(from: record)
                    authEnabled = (record["authEnabled"] as? Int64) != 0
                case .failure(let error):
                    if (error as? CKError)?.code == .unknownItem {
                        recordMissing = true
                    }
                }
            }
            operation.fetchRecordsResultBlock = { result in
                if recordFound {
                    continuation.resume(returning: .found(message: message, authEnabled: authEnabled))
                } else if recordMissing {
                    continuation.resume(returning: .notFound)
                } else if case .failure(let error) = result, (error as? CKError)?.code == .unknownItem {
                    continuation.resume(returning: .notFound)
                } else {
                    continuation.resume(returning: .failed)
                }
            }
            database.add(operation)
        }
    }

    private static func broadcastMessage(from record: CKRecord) -> String? {
        guard let activeFrom = record["authMessageActive"] as? Int64, activeFrom > 0 else { return nil }
        if activeFrom != 1 {
            guard Date(timeIntervalSince1970: TimeInterval(activeFrom)) <= .now else { return nil }
        }
        let isJapanese = Locale.current.language.languageCode?.identifier == "ja"
        if isJapanese, let messageJa = record["authMessageJa"] as? String, !messageJa.isEmpty {
            return messageJa
        }
        if let message = record["authMessage"] as? String, !message.isEmpty {
            return message
        }
        return nil
    }
}
