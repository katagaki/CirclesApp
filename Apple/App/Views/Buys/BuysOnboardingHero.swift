import AXiS
import SwiftUI

/// A shared list drawn the way the Buys grid draws one: members join, then each item is
/// assigned and ticked off in turn while the group total fills in.
struct BuysOnboardingHero: View {

    struct Item {
        let tint: Color
        let symbol: String
        let cost: Int
        let buyer: Int
    }

    @State var joinedCount: Int = 0
    @State var boughtCount: Int = 0

    let members: [(nickname: String, pid: Int)] = [("H", 1), ("U", 3), ("K", 6)]

    let items: [Item] = [
        Item(tint: .purple, symbol: "book.closed.fill", cost: 500, buyer: 0),
        Item(tint: .blue, symbol: "photo.fill", cost: 1000, buyer: 1),
        Item(tint: .yellow, symbol: "sparkles", cost: 1500, buyer: 2)
    ]

    var total: Int {
        items.prefix(boughtCount).reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            HStack(spacing: -8.0) {
                ForEach(Array(members.enumerated()), id: \.offset) { index, member in
                    MemberAvatar(nickname: member.nickname, pid: member.pid, size: 28.0)
                        .overlay {
                            Circle().strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 2.0)
                        }
                        .scaleEffect(index < joinedCount ? 1.0 : 0.2)
                        .opacity(index < joinedCount ? 1.0 : 0.0)
                }
                Spacer()
            }
            HStack(alignment: .top, spacing: 12.0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    tile(item, isBought: index < boughtCount, isAssigned: index < joinedCount)
                }
            }
            HStack {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 72.0, height: 10.0)
                Spacer()
                Text("Buys.CostValue.\(total)")
                    .font(.headline)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(total)))
            }
        }
        .padding(18.0)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20.0))
        .accessibilityHidden(true)
        .task {
            await play()
        }
    }

    func tile(_ item: Item, isBought: Bool, isAssigned: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6.0) {
            item.tint.opacity(0.25)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    Image(systemName: item.symbol)
                        .font(.system(size: 24.0))
                        .foregroundStyle(item.tint)
                }
                .overlay {
                    Color.black.opacity(isBought ? 0.3 : 0.0)
                }
                .clipShape(.rect(cornerRadius: 10.0))
                .overlay(alignment: .topLeading) {
                    BuyStatusBadge(status: isBought ? .bought : .pending)
                        .padding(6.0)
                }
                .overlay(alignment: .topTrailing) {
                    MemberAvatar(nickname: members[item.buyer].nickname, pid: members[item.buyer].pid, size: 22.0)
                        .padding(6.0)
                        .scaleEffect(isAssigned ? 1.0 : 0.2)
                        .opacity(isAssigned ? 1.0 : 0.0)
                }
            Capsule()
                .fill(Color(.systemGray4))
                .frame(height: 8.0)
                .padding(.trailing, 12.0)
            Text("Buys.CostValue.\(item.cost)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    func play() async {
        guard joinedCount == 0, boughtCount == 0 else { return }
        try? await Task.sleep(for: .seconds(0.4))
        for _ in members {
            withAnimation(.bouncy) { joinedCount += 1 }
            try? await Task.sleep(for: .seconds(0.3))
        }
        try? await Task.sleep(for: .seconds(0.3))
        for _ in items {
            withAnimation(.smooth) { boughtCount += 1 }
            try? await Task.sleep(for: .seconds(0.6))
        }
    }
}
