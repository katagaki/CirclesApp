import SwiftUI

/// The popover for a long-pressed spot, or a tapped closure, anchored where it was pressed
/// the way a circle's popover is.
struct MapRouteHoldLayer: View {

    @Environment(Navigator.self) var navigator

    let zoomScale: CGFloat
    let spaceSize: Int

    var anchor: CGPoint? {
        if let pendingPoint = navigator.pendingPoint {
            return pendingPoint
        }
        return navigator.closures.first { $0.id == navigator.selectedClosureID }?.point
    }

    var sourceRect: CGRect? {
        guard let anchor else { return nil }
        let scale = CGFloat(spaceSize) / Navigator.planningSpaceSize
        let size = CGFloat(spaceSize)
        return CGRect(x: anchor.x * scale - size / 2, y: anchor.y * scale - size / 2, width: size, height: size)
    }

    var body: some View {
        if let sourceRect {
            MapPopover(zoomScale: zoomScale, sourceRect: sourceRect, isDismissing: false) {
                MapRouteHoldPopover()
            }
            .id("\(sourceRect.midX),\(sourceRect.midY),\(navigator.selectedClosureID?.uuidString ?? "")")
        }
    }
}
