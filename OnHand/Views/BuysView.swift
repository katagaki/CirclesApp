//
//  BuysView.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

struct BuysView: View {

    @Environment(OnHandStore.self) var store

    @AppStorage(wrappedValue: 1, "OnHand.Day") var selectedDay: Int

    var body: some View {
        List {
            Section {
                LabeledContent("OnHand.Remaining", value: "¥\(store.remainingCost(on: selectedDay))")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            ForEach(store.favorites(on: selectedDay).filter { !$0.items.isEmpty }) { favorite in
                Section {
                    ForEach(favorite.items) { item in
                        BuyRow(circleID: favorite.id, item: item)
                    }
                } header: {
                    Text(favorite.spaceLabel)
                }
            }
        }
        .navigationTitle("OnHand.Buys")
    }
}

struct CircleBuysView: View {

    @Environment(OnHandStore.self) var store

    let circleID: Int

    var favorite: OnHandFavorite? {
        store.payload.favorites.first { $0.id == circleID }
    }

    var body: some View {
        List {
            if let favorite {
                ForEach(favorite.items) { item in
                    BuyRow(circleID: favorite.id, item: item)
                }
            }
        }
        .navigationTitle(favorite?.spaceLabel ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BuyRow: View {

    @Environment(OnHandStore.self) var store

    let circleID: Int
    let item: OnHandBuyItem

    var isBought: Bool { item.statusValue == 1 }
    var isCancelled: Bool { item.statusValue == 2 }

    var symbolName: String {
        if isBought { return "checkmark.circle.fill" }
        if isCancelled { return "xmark.circle.fill" }
        return "circle"
    }

    var body: some View {
        Button {
            store.cycleBuyItem(circleID: circleID, itemID: item.id)
        } label: {
            HStack {
                Image(systemName: symbolName)
                    .foregroundStyle(isBought ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(item.name)
                        .strikethrough(isCancelled)
                        .foregroundStyle(isCancelled ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                    Text("¥\(item.cost)")
                        .font(.caption2)
                        .strikethrough(isCancelled)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
