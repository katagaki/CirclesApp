import UIKit

extension UIGestureRecognizer {
    // SwiftUI attaches representable recognizers to the page's hosting view, above the UIScrollView.
    var scrollViewUnderTouch: UIScrollView? {
        guard let view else { return nil }
        var current = view.hitTest(location(in: view), with: nil) ?? view.superview
        while let candidate = current {
            if let scrollView = candidate as? UIScrollView {
                return scrollView
            }
            current = candidate.superview
        }
        return nil
    }
}
