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

    @State private var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? 0.7 : 1.0)
            .overlay {
                FastDoubleTapView(onDoubleTap: onDoubleTap, onSingleTap: onSingleTap, isPressed: $isPressed)
            }
    }
}

struct FastDoubleTapView: UIViewRepresentable {
    var onDoubleTap: () -> Void
    var onSingleTap: (() -> Void)?
    @Binding var isPressed: Bool

    func makeUIView(context: Context) -> FastDoubleTapTouchView {
        let view = FastDoubleTapTouchView()
        view.backgroundColor = .clear
        view.onPressStateChange = { pressed in
            context.coordinator.isPressed.wrappedValue = pressed
        }

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

    func updateUIView(_ uiView: FastDoubleTapTouchView, context: Context) {
        context.coordinator.onDoubleTap = onDoubleTap
        context.coordinator.onSingleTap = onSingleTap
        context.coordinator.isPressed = _isPressed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleTap: onDoubleTap, onSingleTap: onSingleTap, isPressed: _isPressed)
    }

    class Coordinator: NSObject {
        var onDoubleTap: () -> Void
        var onSingleTap: (() -> Void)?
        var isPressed: Binding<Bool>

        init(onDoubleTap: @escaping () -> Void, onSingleTap: (() -> Void)?, isPressed: Binding<Bool>) {
            self.onDoubleTap = onDoubleTap
            self.onSingleTap = onSingleTap
            self.isPressed = isPressed
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

class FastDoubleTapTouchView: UIView {
    var onPressStateChange: ((Bool) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onPressStateChange?(true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        onPressStateChange?(false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        onPressStateChange?(false)
    }
}

extension View {
    func onFastDoubleTap(doubleTap: @escaping () -> Void, singleTap: (() -> Void)? = nil) -> some View {
        modifier(FastDoubleTapModifier(onDoubleTap: doubleTap, onSingleTap: singleTap))
    }
}
