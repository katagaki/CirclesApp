import SwiftUI

struct BuyRow: View {

    @Environment(Harness.self) var harness
    let item: BuyItem

    var body: some View {
        HStack(spacing: 12.0) {
            Button {
                if let index = harness.buys.firstIndex(where: { $0.id == item.id }) {
                    harness.buys[index].isBought.toggle()
                }
            } label: {
                Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isBought ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            if let circle = MockData.circle(item.circleID) {
                CircleCut(circle: circle, size: 26.0)
            }
            VStack(alignment: .leading, spacing: 2.0) {
                Text(item.title)
                    .strikethrough(item.isBought)
                    .foregroundStyle(item.isBought ? .secondary : .primary)
                if let circle = MockData.circle(item.circleID) {
                    Text("\(circle.name) · \(circle.spaceName)").font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0.0)
            if let assignee = item.assignee, harness.isSharedBuysActive,
               let member = MockData.members.first(where: { $0.name == assignee }) {
                MemberAvatar(member: member, size: 22.0)
            }
            Text("¥\(item.price)").font(.callout.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}
