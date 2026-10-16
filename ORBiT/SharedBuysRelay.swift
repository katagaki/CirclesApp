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
    /// How much of this device's own history the relay holds, as a gapless prefix.
    case held(Int)
    case failed(String)
    case closed(Int)
}

actor SharedBuysRelay {

    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var handler: (@Sendable (RelayEvent) -> Void)?
    private var isRunning: Bool = false
    private var generation: Int = 0
    private var heartbeatTask: Task<Void, Never>?
    private var lastPong: Date = .distantPast
    private var heldSeen: Bool = false
    private var sentEvidence: Bool = false

    struct Endpoint: Sendable {
        var baseURL: String
        var roomID: String
        var deviceID: String
        var deviceAuthKey: Data
        var sessionKey: Data
        var vector: [String: Int]
        var pushToken: String?
        var pushEnvironment: String
    }

    func connect(_ endpoint: Endpoint, onEvent: @escaping @Sendable (RelayEvent) -> Void) {
        disconnect()
        guard let url = URL(string: "\(endpoint.baseURL)/r/\(endpoint.roomID)") else {
            onEvent(.failed("bad relay URL"))
            return
        }
        handler = onEvent
        isRunning = true
        generation += 1
        heldSeen = false
        let generation = generation
        Task { await self.open(endpoint, url: url, generation: generation) }
    }

    private func open(_ endpoint: Endpoint, url: URL, generation: Int) async {
        guard let (hello, evidence) = await helloData(endpoint),
              isRunning, generation == self.generation else { return }
        var request = URLRequest(url: url)
        request.setValue(hello.base64URL, forHTTPHeaderField: "X-Circles-Hello")
        if let evidence {
            request.setValue(evidence.base64URL, forHTTPHeaderField: "X-Circles-Attest")
        }
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        let session = URLSession(configuration: configuration)
        self.session = session
        let task = session.webSocketTask(with: request)
        self.task = task
        task.resume()
        Task { await self.receive(generation: generation) }
        heartbeatTask = Task { await self.heartbeat(generation: generation) }
    }

    func disconnect() {
        isRunning = false
        heartbeatTask?.cancel()
        heartbeatTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
        handler = nil
    }

    func send(records: [RelayRecord]) async {
        guard let task else { return }
        for page in Self.pages(records) {
            let frame: [String: Any] = ["t": "ops", "o": page.map {
                ["d": $0.device, "n": $0.seq, "b": $0.blob, "a": $0.tag]
            }]
            guard let data = try? JSONSerialization.data(withJSONObject: frame),
                  let text = String(data: data, encoding: .utf8) else { return }
            do {
                try await task.send(.string(text))
            } catch {
                handler?(.failed(error.localizedDescription))
                return
            }
        }
    }

    /// The relay closes a socket whose text frame is larger than this (`MAX_FRAME_BYTES`).
    static let maxFrameBytes = 4096

    /// The relay refuses a frame carrying more than this (`MAX_RECORDS_PER_FRAME`).
    static let maxRecordsPerFrame = 32

    /// Records grouped into frames the relay accepts, by count and by encoded size.
    ///
    /// A signed status flip is around 300 bytes once encoded, so 32 of them are more than
    /// twice what one frame may carry, and the relay would close the socket for it.
    static func pages(_ records: [RelayRecord]) -> [[RelayRecord]] {
        let frameOverhead = #"{"t":"ops","o":[]}"#.utf8.count
        let recordOverhead = #"{"d":"","n":,"b":"","a":""},"#.utf8.count
        var pages: [[RelayRecord]] = []
        var page: [RelayRecord] = []
        var size = frameOverhead
        for record in records {
            let cost = recordOverhead + record.device.utf8.count + String(record.seq).utf8.count
                + record.blob.utf8.count + record.tag.utf8.count
            if !page.isEmpty, size + cost > maxFrameBytes || page.count == maxRecordsPerFrame {
                pages.append(page)
                page = []
                size = frameOverhead
            }
            page.append(record)
            size += cost
        }
        if !page.isEmpty { pages.append(page) }
        return pages
    }

    /// Whether the room key may be handed to this relay.
    ///
    /// The hello frame registers a room by uploading `relayAuthKey`, the same key that
    /// backs every `recordTag`. Over `ws://` anyone on the path recovers it and can
    /// forge records for any device, so the key only travels over TLS — or to a
    /// development server on this machine, which includes the Android emulator's alias
    /// for its host. A relay that has not seen the key answers a hello with
    /// `CLOSE_UNKNOWN_ROOM`, which is a diagnosable failure rather than a silent leak.
    static func allowsKeyUpload(_ baseURL: String) -> Bool {
        guard let url = URL(string: baseURL), let scheme = url.scheme?.lowercased() else { return false }
        if scheme == "wss" || scheme == "https" { return true }
        guard let host = url.host?.lowercased() else { return false }
        return ["localhost", "127.0.0.1", "::1", "10.0.2.2"].contains(host)
    }

    /// The hello JSON and, when this device can attest, evidence bound to those exact bytes.
    private func helloData(_ endpoint: Endpoint) async -> (Data, Data?)? {
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
        let deviceTag = SharedBuysCrypto.helloTag(
            deviceID: endpoint.deviceID,
            timestamp: timestamp,
            relayAuthKey: SymmetricKey(data: endpoint.deviceAuthKey)
        )
        var frame: [String: Any] = [
            "t": "hello",
            "d": endpoint.deviceID,
            "v": endpoint.vector,
            "ts": timestamp,
            "a": tag.base64URL,
            "x": endpoint.deviceAuthKey.base64URL,
            "da": deviceTag.base64URL
        ]
        if Self.allowsKeyUpload(endpoint.baseURL) {
            frame["k"] = relayAuthKey.withUnsafeBytes { Data($0) }.base64URL
        }
        if let pushToken = endpoint.pushToken {
            frame["p"] = ["pl": "apns", "tk": pushToken, "e": endpoint.pushEnvironment]
        }
        guard let hello = try? JSONSerialization.data(withJSONObject: frame) else { return nil }
        let evidence = await SharedBuysAttestation.shared.evidence(roomID: endpoint.roomID, hello: hello)
        sentEvidence = evidence != nil
        guard let evidence else { return (hello, nil) }
        return (hello, try? JSONSerialization.data(withJSONObject: evidence.frame))
    }

    private func receive(generation: Int) async {
        while isRunning, generation == self.generation, let task {
            do {
                let message = try await task.receive()
                guard generation == self.generation else { return }
                guard case .string(let text) = message else { continue }
                if text == "pong" {
                    lastPong = .now
                    continue
                }
                guard
                      let data = text.data(using: .utf8),
                      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    continue
                }
                switch object["t"] as? String {
                case "held":
                    heldSeen = true
                    handler?(.connected)
                    handler?(.held(object["n"] as? Int ?? 0))
                case "ops":
                    // A relay that predates `held` answers the hello with ops alone, so
                    // it is treated as holding nothing and gets everything re-sent.
                    if !heldSeen {
                        heldSeen = true
                        handler?(.held(0))
                    }
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
                    await fail(object["c"] as? String ?? "error")
                default:
                    continue
                }
            } catch {
                guard generation == self.generation else { return }
                if isRunning {
                    if let response = task.response as? HTTPURLResponse,
                       let slug = Self.refusalSlugs[response.statusCode] {
                        await fail(slug)
                    } else {
                        let code = task.closeCode.rawValue
                        handler?(code == 0 ? .failed(error.localizedDescription) : .closed(code))
                    }
                }
                isRunning = false
                return
            }
        }
    }

    /// The relay refused a hello this device cannot ever satisfy.
    ///
    /// Reported instead of `auth` when we sent no attestation and the relay demanded
    /// one, which is the permanent case: App Attest is unsupported here — the Simulator,
    /// Mac and Catalyst, most app extensions — or Play has nothing to say about this
    /// device. Reconnecting would be refused identically every 30 seconds for the rest
    /// of the room's life, so the session stops instead and waits for a relaunch.
    static let unattestedSlug = "unattested"

    /// The upgrade refusals the relay distinguishes by status, since a failed WebSocket
    /// upgrade exposes no response body: 403 is the attestation, 401 the hello itself.
    static let refusalSlugs = [401: "auth", 403: "attest", 429: "rate"]

    /// Reports a relay error, forgetting the enrollment when it rejected our attestation.
    ///
    /// A stale enrollment can only keep failing: the key the relay has on file is not
    /// the one this install is signing with, so the next hello has to attest afresh.
    private func fail(_ code: String) async {
        guard code == "attest" else {
            handler?(.failed(code))
            return
        }
        await SharedBuysAttestation.shared.invalidate()
        guard sentEvidence else {
            // Swallow the close that follows, so the session sees one terminal event.
            isRunning = false
            handler?(.failed(Self.unattestedSlug))
            return
        }
        handler?(.failed(code))
    }

    private func heartbeat(generation: Int) async {
        while isRunning, generation == self.generation {
            try? await Task.sleep(for: .seconds(240))
            guard !Task.isCancelled, isRunning, generation == self.generation, let task else { return }
            let sent = Date.now
            do {
                try await task.send(.string("ping"))
            } catch {
                handler?(.failed(error.localizedDescription))
                return
            }
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled, isRunning, generation == self.generation else { return }
            if lastPong < sent {
                task.cancel(with: .goingAway, reason: Data("heartbeat timeout".utf8))
                handler?(.failed("heartbeat timeout"))
                isRunning = false
                return
            }
        }
    }
}
