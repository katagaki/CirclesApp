//
//  SharedItemRow.swift
//  SharedBuys
//

import SwiftUI

struct SharedItemRow: View {

    @Environment(Mesh.self) var mesh
    let item: SharedItem
    let onAssign: () -> Void

    var device: DeviceNode { mesh.focused }
    var assignee: Member? { mesh.member(pid: item.assignee) }
    var isMine: Bool { item.assignee == device.member.id }

    var body: some View {
        HStack(spacing: 10.0) {
            Button {
                withAnimation(.smooth.speed(2.0)) {
                    device.makeOp(
                        .setStatus,
                        itemID: item.id,
                        circleID: item.circleID,
                        value: item.status.next.rawValue
                    )
                    mesh.converge()
                }
            } label: {
                Image(systemName: item.status.symbolName)
                    .font(.system(size: 20.0))
                    .foregroundStyle(statusColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2.0) {
                Text(item.name)
                    .strikethrough(item.status == .cancelled)
                    .foregroundStyle(item.status == .cancelled ? .secondary : .primary)
                if item.status != .pending, let toucher = mesh.member(pid: item.lastTouchedBy),
                   toucher.id != device.member.id {
                    Group {
                        if item.status == .bought {
                            Text("\(toucher.nickname) bought this")
                        } else {
                            Text("\(toucher.nickname) cancelled this")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("¥\(item.cost)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .strikethrough(item.status == .cancelled)

            Button(action: onAssign) {
                if let assignee {
                    MemberAvatar(member: assignee, size: 26.0)
                        .overlay {
                            Circle()
                                .strokeBorder(isMine ? Color.accentColor : .clear, lineWidth: 2.0)
                        }
                } else {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 22.0))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .listRowBackground(isMine ? Color.accentColor.opacity(0.07) : nil)
    }

    var statusColor: Color {
        switch item.status {
        case .pending: .secondary
        case .bought: .accentColor
        case .cancelled: .red.opacity(0.7)
        }
    }
}
