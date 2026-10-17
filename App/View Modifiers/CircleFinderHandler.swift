import SwiftUI
import AXiS

/// Opens the circles that App Intents, Visual Intelligence and shared posts ask for.
struct CircleFinderHandlerModifier: ViewModifier {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    @State var router = CircleFinderRouter.shared
    @State var circleToOpen: ComiketCircle?

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(
                get: { router.pendingText != nil },
                set: { if !$0 { router.pendingText = nil } }
            )) {
                unifier.show()
                if let circleToOpen {
                    self.circleToOpen = nil
                    unifier.append(.circleDetail(circle: circleToOpen))
                }
            } content: {
                if let text = router.pendingText {
                    CircleFinderView(text: text) { circle in
                        circleToOpen = circle
                    }
                }
            }
            .onChange(of: router.pendingText) { _, newValue in
                if newValue != nil {
                    unifier.hide()
                }
            }
            .task(id: router.pendingCircle) {
                guard let identifier = router.pendingCircle else { return }
                // A cold launch from an intent arrives before the catalog is open, and a
                // circle picked in the attachment sheet arrives before that sheet has gone.
                var attempts = 0
                while (database.getTextDatabase() == nil || oasis.isShowing
                       || unifier.pendingAttachmentData != nil) && attempts < 60 {
                    attempts += 1
                    try? await Task.sleep(for: .milliseconds(500))
                }
                guard !Task.isCancelled else { return }
                router.pendingCircle = nil
                guard let parsed = CircleEntity.parse(identifier),
                      parsed.eventNumber == planner.activeEventNumber,
                      let circle = database.circles([parsed.circleID]).first else { return }
                unifier.append(.circleDetail(circle: circle))
            }
    }
}

extension View {
    func circleFinderHandler() -> some View {
        self.modifier(CircleFinderHandlerModifier())
    }
}
