//
//  SharedBuysListView.swift
//  SharedBuys
//

import SwiftUI

struct SharedBuysListView: View {

    @Environment(Mesh.self) var mesh
    @Binding var isShowingSession: Bool

    @State var isShowingAddSheet: Bool = false
    @State var assignmentTarget: SharedItem?

    var device: DeviceNode { mesh.focused }

    var circles: [SharedCircle] {
        let circleIDs = Set(device.items.map(\.circleID))
        return SampleData.circles.filter { circleIDs.contains($0.id) }
    }

    var body: some View {
        Group {
            if !device.isSessionActive {
                List {
                    Section {
                        Button {
                            mesh.join(device)
                        } label: {
                            Label("Join a shared list", systemImage: "qrcode.viewfinder")
                        }
                        Button {
                            mesh.join(device)
                        } label: {
                            Label("Start a shared list", systemImage: "person.2.badge.plus")
                        }
                    } footer: {
                        Text("Your own Buys stay private. A shared list is a separate list that "
                             + "everyone in the session can see and edit.")
                    }
                    Section {
                        ContentUnavailableView(
                            "No shared list",
                            systemImage: "bag",
                            description: Text("Scan a friend's QR code to join theirs.")
                        )
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
            } else {
                List {
                    Section {
                        SharedWithRow(device: device) {
                            isShowingSession = true
                        }
                    } footer: {
                        if mesh.pendingCount(for: device) > 0 {
                            Text("Some changes haven't reached everyone yet.")
                        }
                    }
                    ForEach(circles) { circle in
                        Section {
                            ForEach(device.items(forCircle: circle.id)) { item in
                                SharedItemRow(item: item) {
                                    assignmentTarget = item
                                }
                            }
                        } header: {
                            HStack(spacing: 6.0) {
                                Text(circle.name)
                                    .fontWeight(.semibold)
                                SpacePill(text: circle.space)
                                Spacer()
                                Text("Day \(circle.day)")
                                    .foregroundStyle(.tertiary)
                            }
                            .textCase(nil)
                            .font(.subheadline)
                        }
                    }
                    Section {
                        Button {
                            isShowingAddSheet = true
                        } label: {
                            Label("Add a shared item", systemImage: "plus")
                                .font(.subheadline)
                        }
                    }
                    TotalsSection(device: device)
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddItemSheet()
        }
        .sheet(item: $assignmentTarget) { item in
            AssignSheet(item: item)
        }
    }
}

struct TotalsSection: View {

    let device: DeviceNode

    var mine: Int {
        device.items
            .filter { $0.assignee == device.member.id && $0.status != .cancelled }
            .reduce(0) { $0 + $1.cost }
    }

    var total: Int {
        device.items
            .filter { $0.status != .cancelled }
            .reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        Section {
            HStack {
                Text("Your share")
                Spacer()
                Text("¥\(mine)")
                    .monospacedDigit()
            }
            HStack {
                Text("Group total")
                    .fontWeight(.bold)
                Spacer()
                Text("¥\(total)")
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
        .contentTransition(.numericText())
        .animation(.smooth, value: total)
    }
}
