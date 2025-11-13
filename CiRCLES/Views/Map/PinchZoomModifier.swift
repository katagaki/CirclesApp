//
//  PinchZoomModifier.swift
//  CiRCLES
//
//  Created by Copilot on 2025/11/13.
//

import SwiftUI
import UIKit

/// A ViewModifier that adds UIKit-based pinch-to-zoom with gesture location tracking
struct PinchZoomModifier: ViewModifier {
    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var isPinching: Bool
    let onScaleChange: (CGFloat) -> Void
    let onPinchEnd: (CGFloat) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                PinchGestureView(
                    scale: $scale,
                    anchor: $anchor,
                    isPinching: $isPinching,
                    onScaleChange: onScaleChange,
                    onPinchEnd: onPinchEnd
                )
            )
    }
}

/// UIViewRepresentable that wraps UIPinchGestureRecognizer
struct PinchGestureView: UIViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var isPinching: Bool
    let onScaleChange: (CGFloat) -> Void
    let onPinchEnd: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            scale: $scale,
            anchor: $anchor,
            isPinching: $isPinching,
            onScaleChange: onScaleChange,
            onPinchEnd: onPinchEnd
        )
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var scale: CGFloat
        @Binding var anchor: UnitPoint
        @Binding var isPinching: Bool
        let onScaleChange: (CGFloat) -> Void
        let onPinchEnd: (CGFloat) -> Void
        
        private var initialScale: CGFloat = 1.0
        
        init(
            scale: Binding<CGFloat>,
            anchor: Binding<UnitPoint>,
            isPinching: Binding<Bool>,
            onScaleChange: @escaping (CGFloat) -> Void,
            onPinchEnd: @escaping (CGFloat) -> Void
        ) {
            _scale = scale
            _anchor = anchor
            _isPinching = isPinching
            self.onScaleChange = onScaleChange
            self.onPinchEnd = onPinchEnd
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view = gesture.view else { return }
            
            switch gesture.state {
            case .began:
                initialScale = scale
                isPinching = true
                
                // Calculate anchor point relative to the view
                let location = gesture.location(in: view)
                let x = location.x / view.bounds.width
                let y = location.y / view.bounds.height
                anchor = UnitPoint(x: x, y: y)
                
            case .changed:
                let newScale = initialScale * gesture.scale
                scale = newScale
                onScaleChange(newScale)
                
            case .ended, .cancelled:
                let finalScale = initialScale * gesture.scale
                onPinchEnd(finalScale)
                isPinching = false
                
            default:
                break
            }
        }
        
        // Allow simultaneous gestures (for ScrollView compatibility)
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

extension View {
    func pinchToZoom(
        scale: Binding<CGFloat>,
        anchor: Binding<UnitPoint>,
        isPinching: Binding<Bool>,
        onScaleChange: @escaping (CGFloat) -> Void,
        onPinchEnd: @escaping (CGFloat) -> Void
    ) -> some View {
        self.modifier(
            PinchZoomModifier(
                scale: scale,
                anchor: anchor,
                isPinching: isPinching,
                onScaleChange: onScaleChange,
                onPinchEnd: onPinchEnd
            )
        )
    }
}
