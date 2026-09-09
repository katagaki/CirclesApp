//
//  SharedBuyDraftRow.swift
//  CiRCLES
//

import ORBiT
import SwiftUI

struct SharedBuyDraftRow: View {

    @Environment(SharedBuysSession.self) var sharedBuys

    let circleID: Int

    /// The circle's name and space, relayed into the log alongside the first item from
    /// this circle so a guest — who has no catalog database — can still read the header.
    var circleName: String?
    var circleSpace: String?

    @Binding var itemID: String?

    @State private var name: String = ""
    @State private var cost: String = ""
    @State private var syncedName: String = ""
    @State private var syncedCost: Int = 0
    @State private var syncTask: Task<Void, Never>?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        HStack(spacing: 8.0) {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24.0)
            TextField("Buys.ItemName.Placeholder", text: $name)
            TextField("Buys.ItemCost.Placeholder", text: $cost)
                .keyboardType(.numberPad)
                .frame(width: 70.0)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
        .onChange(of: name) { _, _ in scheduleSync() }
        .onChange(of: cost) { _, _ in scheduleSync() }
        .onDisappear {
            syncTask?.cancel()
            syncTask = nil
            sync()
        }
    }

    func scheduleSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .seconds(1.0))
            guard !Task.isCancelled else { return }
            sync()
        }
    }

    func sync() {
        guard !trimmedName.isEmpty else { return }
        let value = Int(cost) ?? 0
        guard let itemID else {
            self.itemID = sharedBuys.addItem(
                name: trimmedName,
                cost: value,
                circleID: circleID,
                circleName: circleName,
                circleSpace: circleSpace
            )
            syncedName = trimmedName
            syncedCost = value
            return
        }
        if trimmedName != syncedName {
            sharedBuys.rename(itemID: itemID, circleID: circleID, to: trimmedName)
            syncedName = trimmedName
        }
        if value != syncedCost {
            sharedBuys.setCost(itemID: itemID, circleID: circleID, to: value)
            syncedCost = value
        }
    }
}
