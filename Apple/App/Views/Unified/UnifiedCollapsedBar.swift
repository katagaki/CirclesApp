import SwiftUI
import AXiS

struct UnifiedCollapsedBar: View {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    @State var circle: ComiketCircle?

    var showsRouteStep: Bool {
        circle == nil && navigator.isActive && (unifier.sheetPath.last ?? unifier.current) == .navi
    }

    var body: some View {
        ZStack(alignment: .top) {
            UnifiedQuickAccessBar()
                .opacity(circle == nil && !showsRouteStep ? 1.0 : 0.0)
                .allowsHitTesting(circle == nil && !showsRouteStep)
            if showsRouteStep {
                UnifiedRouteStepBar()
            } else if let circle {
                UnifiedCompactCircleBar(circle: circle)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: circle?.id)
        .animation(.easeInOut(duration: 0.2), value: showsRouteStep)
        .onChange(of: unifier.isMinimized, initial: true) { _, newValue in
            if newValue {
                circle = unifier.minimizedCircle
            }
        }
        .onChange(of: unifier.sheetPath) { _, _ in
            if unifier.isMinimized {
                circle = unifier.minimizedCircle
            }
        }
    }
}
