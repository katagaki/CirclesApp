//
//  ReachabilitySetup.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/18.
//

import SwiftUI

struct ReachabilitySetupModifier: ViewModifier {

    @Environment(Authenticator.self) var authenticator

    func body(content: Content) -> some View {
        content
            .task {
                // Starting the notifier performs the single connectivity read and drives the
                // initial bootstrap from its callback — no extra synchronous work on the launch path.
                authenticator.setupReachability()
            }
    }
}

extension View {
    func reachabilitySetup() -> some View {
        self.modifier(ReachabilitySetupModifier())
    }
}
