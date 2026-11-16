import SwiftUI

struct PinchAnchorModifier: ViewModifier {

    @Environment(\.pinchItemTracker) var tracker

    var id: Int

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { frame in
                tracker?.frames[id] = frame
            }
            .onDisappear {
                tracker?.frames[id] = nil
            }
    }
}

extension View {
    func pinchAnchor(id: Int) -> some View {
        modifier(PinchAnchorModifier(id: id))
    }
}
