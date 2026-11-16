import UIKit

@MainActor
struct PinchZoomScroller {

    weak var scrollView: UIScrollView?

    func clampedDelta(_ delta: CGFloat, contentHeightChange: CGFloat) -> CGFloat {
        guard let scrollView else { return 0.0 }
        let inset = scrollView.adjustedContentInset
        let minimum = -inset.top
        let maximum = max(minimum, scrollView.contentSize.height + contentHeightChange
                          + inset.bottom - scrollView.bounds.height)
        let current = scrollView.contentOffset.y
        return min(max(current + delta, minimum), maximum) - current
    }

    func layoutAndScroll(by delta: CGFloat) {
        guard let scrollView else { return }
        let target = scrollView.contentOffset.y + delta
        // HACK: SwiftUI resets offsets set before it lays out the new content, snapping lazy stacks to the top
        scrollView.window?.layoutIfNeeded()
        scrollView.contentOffset.y = target
    }
}
