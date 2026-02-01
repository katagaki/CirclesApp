//
//  View+FastDoubleTap.swift
//  CiRCLES
//
//  Created by Antigravity on 2026/02/01.
//

import SwiftUI

struct FastDoubleTapModifier: ViewModifier {
    var onDoubleTap: () -> Void
    var onSingleTap: (() -> Void)?

    func body(content: Content) -> some View {
        content.overlay {
            FastDoubleTapView(onDoubleTap: onDoubleTap, onSingleTap: onSingleTap)
        }
    }
}

struct FastDoubleTapView: UIViewRepresentable {
    var onDoubleTap: () -> Void
    var onSingleTap: (() -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let gesture = FastDoubleTapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        gesture.singleTapHandler = {
            context.coordinator.handleSingleTap()
        }
        view.addGestureRecognizer(gesture)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onDoubleTap = onDoubleTap
        context.coordinator.onSingleTap = onSingleTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleTap: onDoubleTap, onSingleTap: onSingleTap)
    }

    class Coordinator: NSObject {
        var onDoubleTap: () -> Void
        var onSingleTap: (() -> Void)?

        init(onDoubleTap: @escaping () -> Void, onSingleTap: (() -> Void)?) {
            self.onDoubleTap = onDoubleTap
            self.onSingleTap = onSingleTap
        }

        @MainActor
        @objc func handleDoubleTap(_ gesture: FastDoubleTapGestureRecognizer) {
            if gesture.state == .recognized {
                onDoubleTap()
            }
        }

        func handleSingleTap() {
            onSingleTap?()
        }
    }
}

extension View {
    func onFastDoubleTap(doubleTap: @escaping () -> Void, singleTap: (() -> Void)? = nil) -> some View {
        modifier(FastDoubleTapModifier(onDoubleTap: doubleTap, onSingleTap: singleTap))
    }
}
