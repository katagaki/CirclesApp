//
//  PanelView.swift
//  SharedBuys
//

import SwiftUI

enum PanelSegment: String, CaseIterable, Identifiable {
    case circles = "Circles"
    case favorites = "Favorites"
    case buys = "Buys"

    var id: String { rawValue }
}

struct PanelView: View {

    @Environment(Mesh.self) var mesh
    @State var segment: PanelSegment = .buys
    @State var isShowingSession: Bool = false
    @State var isShowingInfoAlert: Bool = false

    var body: some View {
        VStack(spacing: 0.0) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36.0, height: 5.0)
                .padding(.top, 8.0)

            HStack(spacing: 12.0) {
                Button {
                    isShowingInfoAlert = true
                } label: {
                    Image(systemName: "info.circle")
                }
                Picker("", selection: $segment) {
                    ForEach(PanelSegment.allCases) { segment in
                        Text(LocalizedStringKey(segment.rawValue)).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Button {
                } label: {
                    Image(systemName: "chevron.down")
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 10.0)

            switch segment {
            case .buys:
                SharedBuysListView(isShowingSession: $isShowingSession)
            default:
                ContentUnavailableView(
                    "Not in this prototype",
                    systemImage: "square.dashed",
                    description: Text("The \(segment.rawValue) segment is unchanged by this feature.")
                )
            }
        }
        .frame(height: 660.0)
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20.0, topTrailingRadius: 20.0))
        .shadow(color: .black.opacity(0.18), radius: 12.0, y: -2.0)
        .sheet(isPresented: $isShowingSession) {
            SessionView()
        }
        .alert("About shared Buys", isPresented: $isShowingInfoAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Items you add to a shared list are visible to everyone in the session.")
        }
    }
}

struct SharedWithRow: View {

    @Environment(Mesh.self) var mesh
    let device: DeviceNode
    let action: () -> Void

    var others: [Member] {
        mesh.activeDevices.map(\.member).filter { $0.id != device.member.id }
    }

    var title: LocalizedStringKey {
        switch others.count {
        case 0: "Only you so far"
        case 1: "Shared with \(others[0].nickname)"
        case 2: "Shared with \(others[0].nickname) and \(others[1].nickname)"
        default: "Shared with \(others.count) others"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10.0) {
                HStack(spacing: -8.0) {
                    ForEach(mesh.activeDevices) { peer in
                        MemberAvatar(member: peer.member, size: 26.0)
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
        .buttonStyle(.plain)
    }
}
