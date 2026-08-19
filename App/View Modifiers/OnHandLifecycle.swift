//
//  OnHandLifecycle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftData
import SwiftUI
import AXiS

struct OnHandLifecycle: ViewModifier {

    @Environment(\.modelContext) var modelContext
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(Events.self) var events

    @State var isSyncing: Bool = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                OnHandSync.shared.onIntentReceived = { intent in
                    Task { await apply(intent) }
                }
                OnHandSync.shared.activate()
                Task { await pushPayload() }
            }
            .onChange(of: favorites.invalidationID) {
                Task { await pushPayload() }
            }
            .onChange(of: events.activeEventNumber) {
                Task { await pushPayload() }
            }
    }

    func pushPayload() async {
        guard OnHandSync.shared.isWatchReachable, !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let payload = await OnHandPayloadBuilder.build(
            favorites: favorites,
            database: database,
            events: events,
            visitedCircleIDs: visitedCircleIDs()
        )
        guard let payload else { return }
        OnHandSync.shared.send(payload)
    }

    func visitedCircleIDs() -> Set<Int> {
        let eventNumber = events.activeEventNumber
        let descriptor = FetchDescriptor<CirclesVisitEntry>(
            predicate: #Predicate { $0.eventNumber == eventNumber }
        )
        guard let entries = try? modelContext.fetch(descriptor) else { return [] }
        return Set(entries.map { $0.circleID })
    }

    func apply(_ intent: OnHandIntent) async {
        switch intent.kind {
        case .toggleVisited:
            let actor = VisitActor(modelContainer: sharedModelContainer)
            await actor.toggleVisit(circleID: intent.circleID, eventNumber: events.activeEventNumber)
        case .cycleBuyItem:
            guard let itemID = intent.itemID else { return }
            let eventNumber = events.activeEventNumber
            guard let entry = BuysDatabase.shared.entry(for: intent.circleID, eventNumber: eventNumber),
                  var item = entry.items.first(where: { $0.id == itemID }) else { return }
            item.status = item.status.next
            BuysDatabase.shared.updateItem(item, eventNumber: eventNumber)
        }
        await pushPayload()
    }
}

extension View {
    func onHandLifecycle() -> some View {
        modifier(OnHandLifecycle())
    }
}
