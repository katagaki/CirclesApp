import SwiftUI

struct GoSharedStrip: View {

    @Environment(Harness.self) var harness

    var others: [SharedMember] {
        MockData.members.filter { $0.id != "me" }
    }

    var body: some View {
        NavigationLink(value: Feature.sharedBuys) {
            HStack(spacing: 12.0) {
                if harness.isSharedBuysActive {
                    MemberStack(size: 28.0)
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(others.map { "\($0.name) \($0.location)" }.joined(separator: " · "))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .lineLimit(1)
                        Text("\(harness.buys.filter { $0.assignee != nil }.count) items with friends · live")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: Feature.sharedBuys.symbol)
                        .foregroundStyle(.purple)
                        .frame(width: 28.0)
                    Text("Shop together with friends").font(.subheadline.weight(.semibold))
                }
                Spacer(minLength: 0.0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14.0)
            .padding(.vertical, 10.0)
            .background(Color.purple.opacity(0.1), in: .rect(cornerRadius: 18.0))
        }
        .buttonStyle(.plain)
    }
}
