import SwiftUI

struct UnifierPanelModifier: ViewModifier {
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        @Bindable var unifier = unifier
        if unifier.displayMode == .sheet {
            content
                .sheet(isPresented: $unifier.isPresenting) {
                    UnifiedPanel()
                        .navigationTransition(.zoom(sourceID: "BottomPanel", in: namespace))
                }
        } else {
            content
        }
    }
}

extension View {
    func unifierPanel(namespace: Namespace.ID) -> some View {
        self.modifier(UnifierPanelModifier(namespace: namespace))
    }
}
