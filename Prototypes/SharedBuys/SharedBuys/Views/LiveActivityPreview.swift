//
//  LiveActivityPreview.swift
//  SharedBuys
//

import SwiftUI

struct LiveActivityPreview: View {

    @Environment(Mesh.self) var mesh
    let device: DeviceNode

    var mine: [SharedItem] {
        device.items.filter { $0.assignee == device.member.id }
    }

    var remaining: [SharedItem] {
        mine.filter { $0.status == .pending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(spacing: 6.0) {
                Image(systemName: "bag.fill")
                    .font(.caption)
                Text("SHARED BUYS")
                    .font(.caption2)
                    .fontWeight(.heavy)
                Text("· LOCK SCREEN")
                    .font(.system(size: 9.0, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                HStack(spacing: -6.0) {
                    ForEach(mesh.activeDevices) { peer in
                        MemberAvatar(member: peer.member, size: 20.0)
                            .overlay { Circle().strokeBorder(Color.black.opacity(0.4), lineWidth: 1.5) }
                    }
                }
            }
            .foregroundStyle(.white.opacity(0.7))

            if let next = remaining.first {
                Text(next.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(circleName(for: next))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Text("All your items are done")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8.0) {
                ProgressView(
                    value: Double(mine.count - remaining.count),
                    total: Double(max(mine.count, 1))
                )
                .tint(Color.accentColor)
                Text("\(mine.count - remaining.count)/\(mine.count)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(14.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 20.0))
        .padding(.vertical, 4.0)
        .animation(.smooth, value: remaining.count)
    }

    func circleName(for item: SharedItem) -> String {
        let circle = SampleData.circles.first { $0.id == item.circleID }
        guard let circle else { return "" }
        return "\(circle.name) · \(circle.space)"
    }
}
