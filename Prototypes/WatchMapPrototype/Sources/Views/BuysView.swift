import SwiftUI

struct BuysView: View {

    @Environment(CatalogStore.self) private var store

    private var circleIDs: [Int] {
        var seen: Set<Int> = []
        return store.buys.compactMap { seen.insert($0.circleID).inserted ? $0.circleID : nil }
    }

    private var total: Int {
        store.buys.filter { !$0.isBought }.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Remaining", value: "¥\(total)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            ForEach(circleIDs, id: \.self) { circleID in
                if let favorite = store.favorites.first(where: { $0.circle.id == circleID }) {
                    Section(favorite.spaceLabel) {
                        ForEach(store.buys(forCircle: circleID)) { item in
                            BuyRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Buys")
    }
}

struct BuyRow: View {

    @Environment(CatalogStore.self) private var store

    let item: BuyItem

    var body: some View {
        Button {
            store.toggleBuy(item)
        } label: {
            HStack {
                Image(systemName: item.isBought ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isBought ? .green : .secondary)
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(item.name)
                        .strikethrough(item.isBought)
                    Text("¥\(item.cost)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
