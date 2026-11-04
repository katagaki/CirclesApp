import AXiS
import SwiftUI

struct MyBuyItemTile: View {

    @Environment(Events.self) var planner

    let item: BuyItem
    @Binding var expandedImage: UIImage?
    let onReload: () -> Void

    var body: some View {
        BuyItemTile(
            name: item.name,
            cost: item.cost,
            photo: item.imageData,
            status: item.status,
            onToggle: toggle,
            onPhotoTap: { expandedImage = $0 },
            accessory: { EmptyView() }
        )
    }

    func toggle() {
        var updated = item
        updated.status = item.status.next
        BuysDatabase.shared.updateItem(updated, eventNumber: planner.activeEventNumber)
        withAnimation(.smooth.speed(2.0)) {
            onReload()
        }
    }
}
