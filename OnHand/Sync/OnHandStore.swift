//
//  OnHandStore.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import Foundation
import Observation
import SwiftUI
import WatchConnectivity

@Observable
@MainActor
final class OnHandStore {

    var payload: OnHandPayload = .empty
    var hasReceivedPayload: Bool = false

    @ObservationIgnored private let connection = OnHandConnection()

    init() {
        payload = OnHandPayloadCache.load() ?? .empty
        hasReceivedPayload = payload.generatedAt != .distantPast
    }

    func activate() {
        connection.onPayloadReceived = { [weak self] payload in
            guard let self else { return }
            self.payload = payload
            self.hasReceivedPayload = true
            OnHandPayloadCache.save(payload)
        }
        connection.activate()
    }

    // MARK: Reading

    func favorites(on day: Int) -> [OnHandFavorite] {
        payload.favorites
            .filter { $0.day == day }
            .sorted { $0.spaceLabel < $1.spaceLabel }
    }

    func day(id: Int) -> OnHandDay? {
        payload.days.first { $0.id == id }
    }

    func nextStop(on day: Int) -> (favorite: OnHandFavorite, position: Int, total: Int)? {
        let route = favorites(on: day)
        guard !route.isEmpty else { return nil }
        let index = route.firstIndex { !$0.isVisited } ?? 0
        return (route[index], index + 1, route.count)
    }

    func remainingCost(on day: Int) -> Int {
        favorites(on: day)
            .flatMap { $0.items }
            .filter { $0.statusValue == 0 }
            .reduce(0) { $0 + $1.cost }
    }

    // MARK: Writing

    func toggleVisited(_ circleID: Int) {
        guard let index = payload.favorites.firstIndex(where: { $0.id == circleID }) else { return }
        payload.favorites[index].isVisited.toggle()
        OnHandPayloadCache.save(payload)
        connection.send(OnHandIntent(kind: .toggleVisited, circleID: circleID, itemID: nil))
    }

    func cycleBuyItem(circleID: Int, itemID: String) {
        guard let favoriteIndex = payload.favorites.firstIndex(where: { $0.id == circleID }),
              let itemIndex = payload.favorites[favoriteIndex].items.firstIndex(where: { $0.id == itemID })
        else { return }
        let current = payload.favorites[favoriteIndex].items[itemIndex].statusValue
        payload.favorites[favoriteIndex].items[itemIndex].statusValue = (current + 1) % 3
        OnHandPayloadCache.save(payload)
        connection.send(OnHandIntent(kind: .cycleBuyItem, circleID: circleID, itemID: itemID))
    }
}

enum OnHandPayloadCache {

    private static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appending(path: "OnHandPayload.json")
    }

    static func load() -> OnHandPayload? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(OnHandPayload.self, from: data)
    }

    static func save(_ payload: OnHandPayload) {
        guard let fileURL, let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

final class OnHandConnection: NSObject, WCSessionDelegate, @unchecked Sendable {

    @MainActor var onPayloadReceived: ((OnHandPayload) -> Void)?

    private var activeSession: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    func activate() {
        guard let activeSession else { return }
        activeSession.delegate = self
        if activeSession.activationState != .activated {
            activeSession.activate()
        }
        deliver(activeSession.receivedApplicationContext)
    }

    func send(_ intent: OnHandIntent) {
        guard let activeSession, activeSession.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(intent) else { return }
        let contents: [String: Any] = [OnHandMessage.intent: data]
        if activeSession.isReachable {
            activeSession.sendMessage(contents, replyHandler: nil) { _ in
                activeSession.transferUserInfo(contents)
            }
        } else {
            activeSession.transferUserInfo(contents)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        deliver(session.receivedApplicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        deliver(context)
    }

    private nonisolated func deliver(_ context: [String: Any]) {
        guard let data = context[OnHandMessage.payload] as? Data,
              let payload = try? JSONDecoder().decode(OnHandPayload.self, from: data) else {
            return
        }
        Task { @MainActor in
            self.onPayloadReceived?(payload)
        }
    }
}
