import SwiftUI

/// Search starts a new route, so it is taken away while one is running.
struct NaviSearchModifier: ViewModifier {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    @Binding var text: String
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if navigator.isActive {
            content
        } else {
            content
                .searchable(
                    text: $text,
                    isPresented: $isPresented,
                    placement: unifier.displayMode == .panel && unifier.isPanelSideDocked
                        ? .navigationBarDrawer(displayMode: .always)
                        : .toolbar,
                    prompt: "Circles.Search.Prompt"
                )
        }
    }
}
