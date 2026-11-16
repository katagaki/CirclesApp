import SwiftUI

@Animatable
struct PinchZoomHeightModifier<Session: PinchZoomSession>: ViewModifier {

    @AnimatableIgnored var session: Session?
    var progress: CGFloat
    var focusY: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(height: session?.contentBottom(progress: progress, focusY: focusY), alignment: .top)
    }
}
