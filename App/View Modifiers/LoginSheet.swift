import SwiftUI

struct LoginSheetModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator

    func body(content: Content) -> some View {
        @Bindable var authenticator = authenticator
        content
            .sheet(isPresented: $authenticator.isAuthenticating) {
                authenticator.didFinishAuthenticating = true
            } content: {
                LoginView()
                    .environment(authenticator)
                    .interactiveDismissDisabled()
            }
    }
}

extension View {
    func loginSheet() -> some View {
        self.modifier(LoginSheetModifier())
    }
}
