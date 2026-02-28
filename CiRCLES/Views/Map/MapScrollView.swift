//
//  MapScrollView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/13.
//

import SwiftUI
import UIKit

struct MapScrollView<Content: View>: UIViewRepresentable {

    @Environment(Mapper.self) var mapper

    @Binding var zoomScale: CGFloat
    let content: Content

    init(zoomScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._zoomScale = zoomScale
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.clipsToBounds = false
        scrollView.addSubview(hostingController.view)

        context.coordinator.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let hostingController = context.coordinator.hostingController {
            hostingController.rootView = content
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            hostingController.view.invalidateIntrinsicContentSize()
        }

        if scrollView.zoomScale != zoomScale {
            scrollView.setZoomScale(zoomScale, animated: false)
        }

        if let position = mapper.scrollToPosition {
            let zoomScale = scrollView.zoomScale

            // Calculate scaled position based on current zoom
            let scaledX = position.x * zoomScale
            let scaledY = position.y * zoomScale

            let halfWidth = scrollView.bounds.width / 2
            let halfHeight = scrollView.bounds.height / 2

            // Calculate target offset, clamping to valid scroll range
            let centeredX = max(0, min(scaledX - halfWidth,
                                       scrollView.contentSize.width - scrollView.bounds.width))

            // Allow scrolling to top inset (e.g. under navigation bar)
            let minScrollY = -scrollView.safeAreaInsets.top
            let maxScrollY = max(
                minScrollY,
                scrollView.contentSize.height - scrollView.bounds.height + scrollView.safeAreaInsets.bottom
            )

            let centeredY = max(minScrollY, min(scaledY - halfHeight, maxScrollY))

            let centeredOffset = CGPoint(x: centeredX, y: centeredY)
            scrollView.setContentOffset(centeredOffset, animated: true)
            Task {
                mapper.scrollToPosition = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: MapScrollView
        var hostingController: UIHostingController<Content>?

        init(_ parent: MapScrollView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.zoomScale = scrollView.zoomScale
        }
    }
}
