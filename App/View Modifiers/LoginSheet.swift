//
//  LoginSheet.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import SwiftUI

struct LoginSheetModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator

    func body(content: Content) -> some View {
        @Bindable var authenticator = authenticator
        content
            .sheet(isPresented: $authenticator.isAuthenticating) {
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
