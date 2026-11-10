import SwiftUI

struct SharedMemberRow: View {

    let member: SharedMember

    var body: some View {
        HStack(spacing: 12.0) {
            MemberAvatar(member: member, size: 34.0)
            VStack(alignment: .leading, spacing: 4.0) {
                HStack {
                    Text(member.name).font(.body.weight(.medium))
                    Spacer()
                    Text(member.location).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                ProgressView(value: member.progress).tint(member.color)
            }
        }
    }
}
