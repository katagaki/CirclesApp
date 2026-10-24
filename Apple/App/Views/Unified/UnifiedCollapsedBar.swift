import SwiftUI
import AXiS

struct UnifiedCollapsedBar: View {

    @Environment(Unifier.self) var unifier

    @State var circle: ComiketCircle?

    var body: some View {
        ZStack(alignment: .top) {
            UnifiedQuickAccessBar()
                .opacity(circle == nil ? 1.0 : 0.0)
            if let circle {
                UnifiedCompactCircleBar(circle: circle)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: circle?.id)
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
