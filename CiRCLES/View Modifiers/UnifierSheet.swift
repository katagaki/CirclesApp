//
//  UnifierSheet.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/09.
//

import SwiftUI

struct UnifierSheetModifier: ViewModifier {
    @Environment(Authenticator.self) var authenticator
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        @Bindable var authenticator = authenticator
        @Bindable var unifier = unifier
        if UIDevice.current.userInterfaceIdiom == .phone {
            content
                .sheet(isPresented: $unifier.isPresenting) {
                    if authenticator.isAuthenticating {
                        LoginView()
                            .environment(authenticator)
                            .interactiveDismissDisabled()
                    } else {
                        if #available(iOS 26.0, *) {
                            UnifiedPanel()
                                .navigationTransition(.zoom(sourceID: "BottomPanel", in: namespace))
                        } else {
                            UnifiedPanel()
                        }
                    }
                }
        } else {
            content
                .sheet(isPresented: $authenticator.isAuthenticating) {
                    LoginView()
                        .environment(authenticator)
                        .interactiveDismissDisabled()
                }
        }
    }
}

extension View {
    func unifierSheets(namespace: Namespace.ID) -> some View {
        self.modifier(UnifierSheetModifier(namespace: namespace))
    }
}
