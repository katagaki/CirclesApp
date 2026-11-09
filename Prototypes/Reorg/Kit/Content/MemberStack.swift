import SwiftUI

struct MemberStack: View {

    var size: CGFloat = 26.0

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(MockData.members) { member in
                MemberAvatar(member: member, size: size)
            }
        }
    }
}
