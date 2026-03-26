//
//  BuysView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftData
import SwiftUI
import AXiS

struct BuysView: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier

    @Query var allBuyEntries: [CirclesBuyEntry]

    @Namespace var namespace

    var buyEntries: [CirclesBuyEntry] {
        allBuyEntries.filter {
            $0.eventNumber == planner.activeEventNumber &&
            $0.items.contains(where: { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty })
        }
    }

    var totalCost: Int {
        buyEntries.reduce(0) { total, entry in
            total + entry.items
                .filter {
                    !$0.name.trimmingCharacters(in: .whitespaces).isEmpty &&
                    $0.status != .cancelled
                }
                .reduce(0) { $0 + $1.cost }
        }
    }

    var body: some View {
        Group {
            if buyEntries.isEmpty {
                ContentUnavailableView(
                    "Buys.NoBuys",
                    systemImage: "bag",
                    description: Text("Buys.NoBuys.Description")
                )
            } else {
                List {
                    ForEach(buyEntries, id: \.circleID) { entry in
                        buyEntrySection(entry)
                    }
                    Section {
                        HStack {
                            Text("Buys.Total")
                                .fontWeight(.bold)
                            Spacer()
                            Text("Buys.CostValue.\(totalCost)")
                                .fontWeight(.bold)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
            }
        }
        .navigationTitle("ViewTitle.Buys")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    func buyEntrySection(_ entry: CirclesBuyEntry) -> some View {
        let circles = database.circles([entry.circleID])
        let circle = circles.first

        Section {
            ForEach(Array(entry.items.enumerated()), id: \.element.id) { index, item in
                if !item.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        withAnimation(.smooth.speed(2.0)) {
                            entry.items[index].status = item.status.next
                        }
                    } label: {
                        HStack {
                            Text(item.name)
                                .strikethrough(item.status == .cancelled)
                                .foregroundStyle(item.status == .cancelled ? .secondary : .primary)
                            Spacer()
                            Text("Buys.CostValue.\(item.cost)")
                                .foregroundStyle(.secondary)
                                .strikethrough(item.status == .cancelled)
                            if item.status == .bought {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            if let circle {
                Button {
                    unifier.append(.circleDetail(circle: circle))
                } label: {
                    HStack(spacing: 6.0) {
                        Text(circle.circleName)
                            .fontWeight(.semibold)
                        if let spaceName = circle.spaceName() {
                            CircleBlockPill(LocalizedStringKey(spaceName))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("Buys.UnknownCircle.\(entry.circleID)")
            }
        }
    }
}
