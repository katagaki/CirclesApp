import SwiftUI
import AXiS

struct BuysEntrySection: View {

    @Environment(Database.self) var database

    let entry: BuyEntry
    @Binding var expandedImage: UIImage?
    let onReload: () -> Void

    var body: some View {
        let circle = database.circles([entry.circleID]).first

        Section {
            BuyItemGrid {
                ForEach(entry.items.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) { item in
                    MyBuyItemTile(item: item, expandedImage: $expandedImage, onReload: onReload)
                }
            }
        } header: {
            if let circle {
                BuysCircleLink(circle: circle)
            } else {
                Text("Buys.UnknownCircle.\(entry.circleID)")
            }
        }
    }
}

struct BuysCircleLink: View {

    @Environment(Unifier.self) var unifier

    let circle: ComiketCircle

    var body: some View {
        Button {
            unifier.append(.circleDetail(circle: circle))
        } label: {
            HStack(spacing: 6.0) {
                SharedBuyCircleHeader(name: circle.circleName, space: circle.spaceName())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
