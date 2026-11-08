import RADiUS
import SwiftUI

/// Moves the dragged colour into the slot it is held over, so the grid rearranges under
/// the finger instead of only on release.
struct RoutePriorityDropDelegate: DropDelegate {

    let target: WebCatalogColor
    @Binding var order: [WebCatalogColor]
    @Binding var dragging: WebCatalogColor?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }
        withAnimation(.smooth) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}
