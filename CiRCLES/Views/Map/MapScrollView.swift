//
//  MapScrollView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/13.
//

import SwiftUI
import UIKit

struct MapScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    @Binding var scrollToPosition: CGPoint?

    init(
        scrollToPosition: Binding<CGPoint?> = .constant(nil),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self._scrollToPosition = scrollToPosition
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator
        scrollView.contentInsetAdjustmentBehavior = .always

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
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
            hostingController.view.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let hostingController = context.coordinator.hostingController {
            hostingController.rootView = content
            hostingController.view.setNeedsLayout()
        }

        if let position = scrollToPosition {
            let effectiveHeight = scrollView.bounds.height + scrollView.safeAreaInsets.top
            let halfWidth = scrollView.bounds.width / 2
            let halfHeight = effectiveHeight / 2

            let centeredX = max(0, min(position.x - halfWidth,
                                       scrollView.contentSize.width - scrollView.bounds.width))
            let centeredY = max(0, min(position.y - halfHeight,
                                       scrollView.contentSize.height - scrollView.bounds.height))

            let centeredOffset = CGPoint(x: centeredX, y: centeredY)
            scrollView.setContentOffset(centeredOffset, animated: true)
            Task {
                scrollToPosition = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
    }
}
