import AXiS
import ORBiT
import SwiftUI

/// The Buys at the circle the route is heading to, with the same actions as in the Buys tab.
struct NaviBuysCarousel: View {

    @Environment(Events.self) var planner
    @Environment(SharedBuysSession.self) var sharedBuys

    let circleID: Int

    @State var revision: Int = 0
    @State var expandedImage: UIImage?
    @State var assignmentTarget: SharedBuyItem?

    @State var width: CGFloat = 0.0

    /// How far a grouped list's row content sits inside its section, so tiles here come out
    /// the same size as in the Buys tab's grid.
    let listRowInset: CGFloat = 15.5

    /// How far a grouped list's sections reach past the content beside them.
    let sectionOutset: CGFloat = 3.5

    var tileWidth: CGFloat {
        BuyItemGridMetrics.tileWidth(in: width + (sectionOutset - listRowInset) * 2.0)
    }

    var ownItems: [BuyItem] {
        _ = revision
        return BuysDatabase.shared.entry(for: circleID, eventNumber: planner.activeEventNumber)?
            .items.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty } ?? []
    }

    var sharedItems: [SharedBuyItem] {
        sharedBuys.isActive ? sharedBuys.items.filter { $0.circleID == circleID } : []
    }

    var body: some View {
        let ownItems = ownItems
        let sharedItems = sharedItems
        Group {
            if !ownItems.isEmpty || !sharedItems.isEmpty {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: BuyItemGridMetrics.spacing) {
                        ForEach(ownItems) { item in
                            MyBuyItemTile(item: item, expandedImage: $expandedImage, onReload: reload)
                                .frame(width: tileWidth)
                        }
                        ForEach(sharedItems) { item in
                            SharedBuyItemTile(
                                item: item,
                                onAssign: { assignmentTarget = item },
                                onViewPhoto: { expandedImage = $0 }
                            )
                            .frame(width: tileWidth)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, listRowInset, for: .scrollContent)
                .contentMargins(.vertical, 14.0, for: .scrollContent)
                .scrollIndicators(.hidden)
                .background(.fill.quaternary, in: .rect(cornerRadius: 26.0))
                .clipShape(.rect(cornerRadius: 26.0))
                .padding(.horizontal, -sectionOutset)
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .fullScreenCover(item: Binding(
            get: { expandedImage.map { ExpandedBuyImage(image: $0) } },
            set: { if $0 == nil { expandedImage = nil } }
        )) { item in
            BuyItemImageViewer(image: item.image)
        }
        .sheet(item: $assignmentTarget) { item in
            SharedBuyAssignSheet(item: item)
        }
    }

    func reload() {
        revision += 1
    }
}
