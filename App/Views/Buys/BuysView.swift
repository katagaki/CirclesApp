//
//  BuysView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI
import AXiS

struct BuysView: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections

    @State var buyEntries: [BuyEntry] = []
    @State var dayMappedCircleIDs: [Int: Int] = [:]
    @State var expandedImage: UIImage?
    @State var isShowingInfoAlert: Bool = false

    var entriesWithItems: [BuyEntry] {
        buyEntries.filter {
            $0.items.contains(where: { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty })
        }
    }

    var visibleEntries: [BuyEntry] {
        guard let selectedDayID = selections.date?.id else { return entriesWithItems }
        return entriesWithItems.filter { dayMappedCircleIDs[$0.circleID] == selectedDayID }
    }

    var totalCost: Int {
        visibleEntries.reduce(0) { total, entry in
            total + entry.items
                .filter {
                    !$0.name.trimmingCharacters(in: .whitespaces).isEmpty &&
                    $0.status != .cancelled
                }
                .reduce(0) { $0 + $1.cost }
        }
    }

    var body: some View {
        ZStack {
            if visibleEntries.isEmpty {
                if entriesWithItems.isEmpty {
                    ContentUnavailableView(
                        "Buys.NoBuys",
                        systemImage: "bag",
                        description: Text("Buys.NoBuys.Description")
                    )
                } else {
                    ContentUnavailableView(
                        "Buys.NoBuysOnDay",
                        systemImage: "bag",
                        description: Text("Buys.NoBuysOnDay.Description")
                    )
                }
            } else {
                List {
                    ForEach(visibleEntries) { entry in
                        BuysEntrySection(entry: entry, expandedImage: $expandedImage, onReload: reloadEntries)
                    }
                    Section {
                        HStack {
                            Text("Buys.Total")
                                .fontWeight(.bold)
                            Spacer()
                            Text("Buys.CostValue.\(totalCost)")
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
            }
        }
        .fullScreenCover(item: Binding(
            get: { expandedImage.map { ExpandedBuyImage(image: $0) } },
            set: { if $0 == nil { expandedImage = nil } }
        )) { item in
            BuyItemImageViewer(image: item.image)
        }
        .navigationTitle("ViewTitle.Buys")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ToolbarItem(placement: .topBarLeading) {
                    infoButton()
                }
            } else {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    infoButton()
                }
                SidebarPositionToolbarItem()
            }
        }
        .alert("Buys.Info.Title", isPresented: $isShowingInfoAlert) {
            Button("Shared.OK", role: .cancel) { }
        } message: {
            Text("Buys.Info.Description")
        }
        .onAppear {
            reloadEntries()
        }
    }

    @ViewBuilder
    func infoButton() -> some View {
        Button {
            isShowingInfoAlert = true
        } label: {
            Image(systemName: "info.circle")
        }
    }

    func reloadEntries() {
        buyEntries = BuysDatabase.shared.entries(for: planner.activeEventNumber)
        reloadDayMappedCircleIDs()
    }

    func reloadDayMappedCircleIDs() {
        let circles = database.circles(buyEntries.map({ $0.circleID }))
        dayMappedCircleIDs = Dictionary(circles.map({ ($0.id, $0.day) }), uniquingKeysWith: { first, _ in first })
    }
}

struct ExpandedBuyImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
