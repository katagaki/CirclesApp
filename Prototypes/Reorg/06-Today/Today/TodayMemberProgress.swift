import SwiftUI

struct TodayMemberProgress: View {

    let member: SharedMember

    var body: some View {
        VStack(alignment: .leading, spacing: 6.0) {
            HStack(spacing: 6.0) {
                MemberAvatar(member: member, size: 24.0)
                Text(member.name).font(.subheadline.weight(.semibold)).lineLimit(1)
            }
            ProgressView(value: member.progress).tint(member.color)
            Text(member.location).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
