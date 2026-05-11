//
//  BuysView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import SwiftUI
import AXiS

struct BuysView: View {

    @Environment(Events.self) var planner

    @State var buyEntries: [BuyEntry] = []
    @State var expandedImage: UIImage?
    @State var isShowingInfoAlert: Bool = false

    var visibleEntries: [BuyEntry] {
        buyEntries.filter {
            $0.items.contains(where: { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty })
        }
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
                ContentUnavailableView(
                    "Buys.NoBuys",
                    systemImage: "bag",
                    description: Text("Buys.NoBuys.Description")
                )
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
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isShowingInfoAlert = true
                } label: {
                    Image(systemName: "info.circle")
                }
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

    func reloadEntries() {
        buyEntries = BuysDatabase.shared.entries(for: planner.activeEventNumber)
    }
}

struct ExpandedBuyImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
