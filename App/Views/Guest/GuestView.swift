//
//  GuestView.swift
//  CiRCLES
//

import ORBiT
import SwiftUI

/// The whole app, for someone who is not signed in.
///
/// A guest has no catalog database, so there is no map to show, nothing to browse and no
/// favourites — the four other tabs would all be empty. What is left is the one thing
/// they came for: the shared list they scanned into, and the ability to tick items off
/// it. The unified shell's bottom panel goes with the rest, since there is nothing to
/// switch between.
struct GuestView: View {

    @Environment(SharedBuysSession.self) var sharedBuys

    @State private var isShowingScanner: Bool = false
    @State private var isShowingMy: Bool = false
    @State private var isConfirmingLeave: Bool = false
    @State private var stackPath: [UnifiedPath] = []

    var body: some View {
        NavigationStack(path: $stackPath) {
            Group {
                if sharedBuys.isActive {
                    joinedList()
                } else {
                    notJoined()
                }
            }
            .navigationTitle("Buys.Shared.Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Tab.My", image: .buttonMy) {
                        isShowingMy = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    GuestMoreMenu(stackPath: $stackPath)
                }
            }
            .navigationDestination(for: UnifiedPath.self) { path in
                path.view()
            }
        }
        .sheet(isPresented: $isShowingScanner) {
            SharedBuysScannerView { url in
                sharedBuys.adoptIdentity()
                sharedBuys.join(url: url, nickname: sharedBuys.nickname)
            }
        }
        .sheet(isPresented: $isShowingMy) {
            NavigationStack {
                GuestMyView()
            }
            .presentationDetents([.large])
        }
        .alert("Alerts.Guest.Leave.Title", isPresented: $isConfirmingLeave) {
            Button("Buys.Shared.End", role: .destructive) {
                sharedBuys.leave()
            }
            Button("Shared.Cancel", role: .cancel) { }
        } message: {
            Text("Alerts.Guest.Leave.Message")
        }
    }

    @ViewBuilder
    func notJoined() -> some View {
        ContentUnavailableView {
            Label("Buys.Guest.NotJoined", systemImage: "qrcode.viewfinder")
        } description: {
            Text("Buys.Guest.NotJoined.Description")
        } actions: {
            Button("Buys.Guest.Scan") {
                isShowingScanner = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func joinedList() -> some View {
        let items = sharedBuys.items
        let circleIDs = Set(items.map(\.circleID))
        List {
            if items.isEmpty {
                Section {
                    Text("Buys.Shared.NoItems.Description")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(Array(circleIDs).sorted(), id: \.self) { circleID in
                Section {
                    ForEach(items.filter { $0.circleID == circleID }) { item in
                        // A guest cannot reassign, so the avatar is shown but does
                        // nothing when tapped — it still says who is responsible.
                        SharedBuyItemRow(item: item) { }
                    }
                } header: {
                    // The only description of a circle a guest will ever have is the one
                    // the contributor relayed into the log when they added the item.
                    if let relayed = sharedBuys.relayedCircles[circleID] {
                        SharedBuyCircleHeader(name: relayed.name, space: relayed.space)
                    } else {
                        Text("Buys.UnknownCircle.\(circleID)")
                    }
                }
            }
            Section {
                HStack {
                    Text("Buys.Shared.GroupTotal")
                        .fontWeight(.bold)
                    Spacer()
                    Text("Buys.CostValue.\(sharedBuys.groupTotal)")
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            } footer: {
                Text("Buys.Guest.ReadOnly")
            }
            Section {
                Button("Buys.Shared.End", role: .destructive) {
                    isConfirmingLeave = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
    }
}
