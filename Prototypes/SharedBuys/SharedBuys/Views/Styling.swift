//
//  Styling.swift
//  SharedBuys
//

import SwiftUI

extension Member {
    var color: Color {
        switch tint {
        case 0: .orange
        case 1: .teal
        default: .purple
        }
    }

    var initial: String {
        String(nickname.prefix(1))
    }
}

struct MemberAvatar: View {

    let member: Member
    var size: CGFloat = 24.0

    var body: some View {
        Circle()
            .fill(member.color.gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(member.initial)
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

struct SpacePill: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .monospaced()
            .padding(.horizontal, 6.0)
            .padding(.vertical, 2.0)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}
