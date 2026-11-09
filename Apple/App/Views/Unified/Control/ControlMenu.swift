import SwiftUI

enum ControlMenuMetrics {
    static let cornerRadius: CGFloat = 32.0
    static let padding: CGFloat = 16.0
    // Concentric with the menu's own corner.
    static let contentCornerRadius: CGFloat = cornerRadius - padding
}

struct ControlMenu<Content: View>: View {
    @Environment(Unifier.self) var unifier

    let contentWidth: CGFloat
    let isContentEdgeToEdge: Bool
    let content: (@escaping () -> Void) -> Content

    let padding: CGFloat = ControlMenuMetrics.padding
    let edgePadding: CGFloat = 8.0
    // Matches the corner of a native iOS 26 popover.
    let cornerRadius: CGFloat = ControlMenuMetrics.cornerRadius

    @State var animationProgress: CGFloat = 0.0
    @State var menuHeight: CGFloat = 0.0

    init(
        contentWidth: CGFloat,
        isContentEdgeToEdge: Bool = false,
        @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
    ) {
        self.contentWidth = contentWidth
        self.isContentEdgeToEdge = isContentEdgeToEdge
        self.content = content
    }

    var anchor: CGRect {
        unifier.controlFrame
    }

    var menuWidth: CGFloat {
        contentWidth + padding * 2.0
    }

    func interpolate(_ from: CGFloat, _ to: CGFloat) -> CGFloat {
        from + (to - from) * animationProgress
    }

    // Grows out of the control's own capsule into the menu, so the two read as one shape.
    var body: some View {
        GeometryReader { proxy in
            let container = proxy.frame(in: .global)
            let originX = interpolate(anchor.minX, menuOriginX(in: container)) - container.minX
            let width = interpolate(anchor.width, menuWidth)
            let height = menuHeight > 0.0 ? interpolate(anchor.height, menuHeight) : anchor.height
            let radius = interpolate(anchor.height / 2.0, cornerRadius)
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { close() }
                Color.clear
                    .frame(width: width, height: height)
                    .glassEffect(.regular, in: shape)
                    .offset(x: originX, y: anchor.minY - container.minY)
                content(close)
                    .padding(.vertical, padding)
                    .padding(.horizontal, isContentEdgeToEdge ? 0.0 : padding)
                    .frame(width: menuWidth)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { menuHeight = $0 }
                    .opacity(animationProgress)
                    .offset(x: originX, y: anchor.minY - container.minY)
                    .mask(alignment: .topLeading) {
                        shape
                            .frame(width: width, height: height)
                            .offset(x: originX, y: anchor.minY - container.minY)
                    }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.smooth(duration: 0.3)) {
                animationProgress = 1.0
            }
        }
    }

    func menuOriginX(in container: CGRect) -> CGFloat {
        let preferred = anchor.minX
        let minimumX = container.minX + edgePadding
        let maximumX = container.maxX - menuWidth - edgePadding
        return min(max(preferred, minimumX), max(minimumX, maximumX))
    }

    func close() {
        withAnimation(.smooth(duration: 0.25)) {
            animationProgress = 0.0
            unifier.presentedControlMenu = nil
        }
    }
}
