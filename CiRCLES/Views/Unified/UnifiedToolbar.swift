//
//  UnifiedToolbar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

struct UnifiedToolbar: ToolbarContent {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    @Binding var viewPath: [UnifiedPath]
    @Binding var isMyComiketPresenting: Bool
    @Binding var isGoingToSignOut: Bool

    let namespace: Namespace.ID

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Tab.My", image: .tabIconMy) {
                unifier.hide()
                isMyComiketPresenting = true
            }
            .matchedTransitionSource(id: "My.View", in: namespace)
        }
        if !oasis.isShowing && !authenticator.isAuthenticating {
            ToolbarItem(placement: .principal) {
                UnifiedControl()
                    .foregroundStyle(.primary)
                    .glassEffectInteractiveIfSupported()
                    .adaptiveShadow()
            }
            ToolbarItem(placement: .topBarTrailing) {
                UnifiedMoreMenu(
                    viewPath: $viewPath,
                    isGoingToSignOut: $isGoingToSignOut
                )
            }
        }
        if #available(iOS 26.0, *) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("Shared.OpenPanel", systemImage: "chevron.up") {
                        unifier.show()
                    }
                }
                .matchedTransitionSource(id: "BottomPanel", in: namespace)
            }
        }
    }
}
