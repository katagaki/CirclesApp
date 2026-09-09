//
//  BuysView.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import AXiS
import ORBiT
import SwiftUI

struct BuysView: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(UserSelections.self) var selections
    @Environment(SharedBuysSession.self) var sharedBuys

    @State var buyEntries: [BuyEntry] = []
    @State var dayMappedCircleIDs: [Int: Int] = [:]
    @State var expandedImage: UIImage?
    @State var isShowingInfoAlert: Bool = false
    @State var isShowingSharedSheet: Bool = false
    @State var scope: BuysScope = .mine
    @State var hasChosenScope: Bool = false
    @State var assignmentTarget: SharedBuyItem?

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
        cost(of: visibleEntries)
    }

    var grandTotalCost: Int {
        cost(of: entriesWithItems)
    }

    func cost(of entries: [BuyEntry]) -> Int {
        entries.reduce(0) { total, entry in
            total + entry.items
                .filter {
                    !$0.name.trimmingCharacters(in: .whitespaces).isEmpty &&
                    $0.status != .cancelled
                }
                .reduce(0) { $0 + $1.cost }
        }
    }

    var body: some View {
        VStack(spacing: 0.0) {
            Picker("", selection: $scope) {
                Text("Buys.Scope.Mine").tag(BuysScope.mine)
                Text("Buys.Scope.Shared").tag(BuysScope.shared)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16.0)
            .padding(.bottom, 8.0)
            if scope == .mine {
                privateBuys()
            } else {
                sharedBuysList()
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
        .sheet(isPresented: $isShowingSharedSheet) {
            SharedBuysSheet()
        }
        .sheet(item: $assignmentTarget) { item in
            SharedBuyAssignSheet(item: item)
        }
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
            if sharedBuys.isActive, !hasChosenScope { scope = .shared }
        }
        .onChange(of: sharedBuys.isActive) { _, isActive in
            if isActive, !hasChosenScope { scope = .shared }
        }
        .onChange(of: scope) { _, _ in
            hasChosenScope = true
        }
    }

    @ViewBuilder
    func privateBuys() -> some View {
        ZStack {
            if visibleEntries.isEmpty {
                if entriesWithItems.isEmpty {
                    ContentUnavailableView(
                        "Buys.NoBuys",
                        systemImage: "bag",
                        description: Text("Buys.NoBuys.Description")
                    )
                } else {
                    VStack(spacing: 0.0) {
                        ContentUnavailableView(
                            "Buys.NoBuysOnDay",
                            systemImage: "bag",
                            description: Text("Buys.NoBuysOnDay.Description")
                        )
                        HStack {
                            Text("Buys.GrandTotal")
                                .fontWeight(.bold)
                            Spacer()
                            Text("Buys.CostValue.\(grandTotalCost)")
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        .padding([.horizontal], 20.0)
                        .padding([.bottom], 20.0)
                    }
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
                        if selections.date != nil {
                            HStack {
                                Text("Buys.GrandTotal")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Buys.CostValue.\(grandTotalCost)")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
            }
        }
    }

    @ViewBuilder
    func sharedBuysList() -> some View {
        let circleIDs = Set(sharedBuys.items.map(\.circleID))
        let circles = database.circles(Array(circleIDs))
        if !sharedBuys.isActive {
            ContentUnavailableView {
                Label("Buys.Shared.NotStarted", systemImage: "person.2")
            } description: {
                Text("Buys.Shared.Explain")
            } actions: {
                Button("Buys.Shared.Start") {
                    sharedBuys.adoptIdentity()
                    sharedBuys.start(
                        eventNumber: planner.activeEventNumber,
                        nickname: sharedBuys.nickname
                    )
                    isShowingSharedSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if sharedBuys.items.isEmpty {
            VStack(spacing: 0.0) {
                List {
                    Section {
                        SharedWithRow()
                            .onTapGesture { isShowingSharedSheet = true }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
                .frame(height: 110.0)
                ContentUnavailableView(
                    "Buys.Shared.NoItems",
                    systemImage: "bag",
                    description: Text("Buys.Shared.NoItems.Description")
                )
            }
        } else {
            List {
                Section {
                    SharedWithRow()
                        .onTapGesture { isShowingSharedSheet = true }
                } footer: {
                    if sharedBuys.hasUnsentChanges {
                        Text("Buys.Shared.Pending")
                    }
                }
                ForEach(Array(circleIDs).sorted(), id: \.self) { circleID in
                    Section {
                        ForEach(sharedBuys.items.filter { $0.circleID == circleID }) { item in
                            SharedBuyItemRow(item: item) { assignmentTarget = item }
                        }
                    } header: {
                        // The catalog is authoritative and current; the log is what a
                        // member without one has. Falling back to it is what keeps a
                        // guest's headers readable instead of "Unknown circle 12345".
                        if let circle = circles.first(where: { $0.id == circleID }) {
                            SharedBuyCircleHeader(
                                name: circle.circleName,
                                space: circle.spaceName()
                            )
                        } else if let relayed = sharedBuys.relayedCircles[circleID] {
                            SharedBuyCircleHeader(name: relayed.name, space: relayed.space)
                        } else {
                            Text("Buys.UnknownCircle.\(circleID)")
                        }
                    }
                }
                Section {
                    HStack {
                        Text("Buys.Shared.YourShare")
                        Spacer()
                        Text("Buys.CostValue.\(sharedBuys.yourShare)")
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Buys.Shared.GroupTotal")
                            .fontWeight(.bold)
                        Spacer()
                        Text("Buys.CostValue.\(sharedBuys.groupTotal)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
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

enum BuysScope: Hashable {
    case mine
    case shared
}

struct SharedWithRow: View {

    @Environment(SharedBuysSession.self) var sharedBuys

    var others: [String] {
        sharedBuys.members
            .filter { $0.key != sharedBuys.actorPID }
            .values
            .sorted()
    }

    var title: LocalizedStringKey {
        switch others.count {
        case 0: "Buys.Shared.OnlyYou"
        case 1: "Buys.Shared.With.\(others[0])"
        case 2: "Buys.Shared.With.\(others[0]).\(others[1])"
        default: "Buys.Shared.With.Others.\(others.count)"
        }
    }

    var body: some View {
        HStack(spacing: 10.0) {
            HStack(spacing: -8.0) {
                ForEach(sharedBuys.members.sorted(by: { $0.value < $1.value }), id: \.key) { member in
                    MemberInitial(nickname: member.value, size: 26.0)
                        .overlay {
                            Circle().strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 2.0)
                        }
                }
            }
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .font(.subheadline)
        .contentShape(.rect)
    }
}

struct ExpandedBuyImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// A shared-list section header, from whichever source could describe the circle.
struct SharedBuyCircleHeader: View {

    let name: String
    let space: String?

    var body: some View {
        HStack(spacing: 6.0) {
            Text(name)
                .fontWeight(.semibold)
            if let space {
                CircleBlockPill(LocalizedStringKey(space))
            }
        }
    }
}
