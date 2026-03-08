//
//  AutomaticGlass.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/09/21.
//

import SwiftUI

struct AutomaticGlassInteractive: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive())
        } else {
            content
        }
    }
}

struct AutomaticGlassButtonStyleProminent: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
        } else {
            content
                .buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    func glassEffectInteractiveIfSupported() -> some View {
        self.modifier(AutomaticGlassInteractive())
    }

    func buttonStyleGlassProminentIfSupported() -> some View {
        self.modifier(AutomaticGlassButtonStyleProminent())
    }
}
