import SwiftUI

struct ReachabilitySetupModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator

    func body(content: Content) -> some View {
        content
            .task {
                authenticator.setupReachability()
            }
    }
}

extension View {
    func reachabilitySetup() -> some View {
        self.modifier(ReachabilitySetupModifier())
    }
}
