import SwiftUI

struct MemberAvatar: View {

    let member: SharedMember
    var size: CGFloat = 32.0

    var body: some View {
        Text(member.initial)
            .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(member.color.gradient, in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: size > 24.0 ? 2.0 : 1.0))
    }
}
