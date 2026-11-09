import SwiftUI

struct FriendsLayerOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var friends: [SharedMember] { MockData.members.filter { $0.id != "me" } }

    func point(for index: Int) -> CGPoint {
        let blockCount = harness.hall.blocks.count
        let rect = layout.slotRect(block: (index * 5 + 2) % blockCount, slot: (index * 7 + 3) % HallMapLayout.slotsPerBlock)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    var body: some View {
        ZStack {
            if harness.isSharedBuysActive {
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, member in
                    VStack(spacing: 2.0) {
                        MemberAvatar(member: member, size: 30.0)
                            .shadow(color: .black.opacity(0.25), radius: 3.0, y: 1.0)
                        Text(member.name)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 5.0)
                            .background(.regularMaterial, in: .capsule)
                    }
                    .position(point(for: index))
                }
            }
        }
    }
}
