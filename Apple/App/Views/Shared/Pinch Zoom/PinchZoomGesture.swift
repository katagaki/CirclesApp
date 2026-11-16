import SwiftUI
import UIKit

struct PinchZoomGesture: UIGestureRecognizerRepresentable {

    var isEnabled: Bool
    var coordinateSpace: String
    var onBegan: (CGPoint, CGRect) -> Void
    var onChanged: (CGFloat, CGPoint) -> Void
    var onEnded: (CGFloat, PinchZoomScroller) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
        let recognizer = UIPinchGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        let coordinator = context.coordinator
        switch recognizer.state {
        case .began:
            coordinator.isEngaged = true
            coordinator.startScale = max(recognizer.scale, 0.01)
            let location = context.converter.location(in: .named(coordinateSpace))
            var viewport = CGRect(x: 0.0, y: location.y - 1000.0, width: 0.0, height: 2000.0)
            if let scrollView = recognizer.scrollViewUnderTouch {
                coordinator.scrollView = scrollView
                scrollView.isScrollEnabled = false
                let locationInScrollView = recognizer.location(in: scrollView)
                viewport = scrollView.bounds.offsetBy(dx: location.x - locationInScrollView.x,
                                                      dy: location.y - locationInScrollView.y)
            }
            onBegan(location, viewport)
        case .changed:
            guard coordinator.isEngaged else { return }
            onChanged(recognizer.scale / coordinator.startScale,
                      context.converter.location(in: .named(coordinateSpace)))
        case .ended, .cancelled, .failed:
            guard coordinator.isEngaged else { return }
            coordinator.isEngaged = false
            coordinator.scrollView?.isScrollEnabled = true
            onEnded(recognizer.velocity, PinchZoomScroller(scrollView: coordinator.scrollView))
            coordinator.scrollView = nil
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var isEngaged = false
        var startScale: CGFloat = 1.0
        weak var scrollView: UIScrollView?

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer.view is UIScrollView
        }
    }
}
