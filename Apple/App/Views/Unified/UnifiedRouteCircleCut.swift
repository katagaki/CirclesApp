import AXiS
import SwiftUI

/// The cut of the circle a step arrives at, standing in for the turn icon. Tapping it opens
/// the circle in the panel.
struct UnifiedRouteCircleCut: View {

    @Environment(Database.self) var database
    @Environment(Unifier.self) var unifier

    @Namespace var namespace

    let circleID: Int

    @State var circle: ComiketCircle?

    var body: some View {
        Group {
            if let circle {
                Button {
                    if unifier.isMinimized || !unifier.isPresenting {
                        unifier.selectedDetent = .height(360)
                    }
                    unifier.append(.circleDetail(circle: circle))
                } label: {
                    CircleCutImage(
                        circle, in: namespace, cutType: .catalog,
                        showSpaceName: .constant(false), showDay: .constant(false)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Rectangle()
                    .fill(.quaternary)
            }
        }
        .frame(width: 56.0, height: 80.0)
        .task(id: circleID) {
            circle = database.circles([circleID]).first
        }
    }
}
