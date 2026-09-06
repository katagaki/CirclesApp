//
//  SharedBuysRelay.swift
//  CiRCLES
//

import CryptoKit
import Foundation

struct RelayRecord: Sendable {
    var device: String
    var seq: Int
    var blob: String
    var tag: String
}

enum RelayEvent: Sendable {
    case connected
    case records([RelayRecord])
    case failed(String)
    case closed(Int)
}

actor SharedBuysRelay {

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var handler: (@Sendable (RelayEvent) -> Void)?
    private var isRunning: Bool = false

    struct Endpoint: Sendable {
        var baseURL: String
        var roomID: String
        var deviceID: String
        var sessionKey: Data
        var vector: [String: Int]
    }

    func connect(_ endpoint: Endpoint, onEvent: @escaping @Sendable (RelayEvent) -> Void) {
        disconnect()
        guard let url = URL(string: "\(endpoint.baseURL)/r/\(endpoint.roomID)") else {
            onEvent(.failed("bad relay URL"))
            return
        }
        handler = onEvent
        isRunning = true
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        let session = URLSession(configuration: configuration)
        self.session = session
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()

        Task { await self.sendHello(endpoint) }
        Task { await self.receive() }
    }

    func disconnect() {
        isRunning = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
        handler = nil
    }

    func send(records: [RelayRecord]) async {
        guard let task, !records.isEmpty else { return }
        let frame: [String: Any] = ["t": "ops", "o": records.map {
            ["d": $0.device, "n": $0.seq, "b": $0.blob, "a": $0.tag]
        }]
        guard let data = try? JSONSerialization.data(withJSONObject: frame),
              let text = String(data: data, encoding: .utf8) else { return }
        do {
            try await task.send(.string(text))
        } catch {
            handler?(.failed(error.localizedDescription))
        }
    }

    private func sendHello(_ endpoint: Endpoint) async {
        guard let task else { return }
        let relayAuthKey = SharedBuysCrypto.derive(
            SharedBuysCrypto.relayAuthInfo,
            from: endpoint.sessionKey
        )
        let timestamp = Int(Date().timeIntervalSince1970)
        let tag = SharedBuysCrypto.helloTag(
            deviceID: endpoint.deviceID,
            timestamp: timestamp,
            relayAuthKey: relayAuthKey
        )
        let frame: [String: Any] = [
            "t": "hello",
            "d": endpoint.deviceID,
            "v": endpoint.vector,
            "k": relayAuthKey.withUnsafeBytes { Data($0) }.base64URL,
            "ts": timestamp,
            "a": tag.base64URL
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: frame),
              let text = String(data: data, encoding: .utf8) else { return }
        do {
            try await task.send(.string(text))
            handler?(.connected)
        } catch {
            handler?(.failed(error.localizedDescription))
        }
    }

    private func receive() async {
        while isRunning, let task {
            do {
                let message = try await task.receive()
                guard case .string(let text) = message,
                      let data = text.data(using: .utf8),
                      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    continue
                }
                switch object["t"] as? String {
                case "ops":
                    let raw = object["o"] as? [[String: Any]] ?? []
                    let records: [RelayRecord] = raw.compactMap { entry in
                        guard let device = entry["d"] as? String,
                              let seq = entry["n"] as? Int,
                              let blob = entry["b"] as? String,
                              let tag = entry["a"] as? String else { return nil }
                        return RelayRecord(device: device, seq: seq, blob: blob, tag: tag)
                    }
                    handler?(.records(records))
                case "err":
                    handler?(.failed(object["c"] as? String ?? "error"))
                default:
                    continue
                }
            } catch {
                if isRunning {
                    let code = task.closeCode.rawValue
                    handler?(code == 0 ? .failed(error.localizedDescription) : .closed(code))
                }
                isRunning = false
                return
            }
        }
    }
}
