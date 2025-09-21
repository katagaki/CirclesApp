//
//  AutomaticGlass.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/09/21.
//

import SwiftUI

struct AutomaticGlass: ViewModifier {
    var bordered: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect()
        } else {
            if bordered {
                content
                    .background(Material.regular)
                    .clipShape(.capsule)
            } else {
                content
            }
        }
    }
}

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

struct AutomaticGlassRounded: ViewModifier {
    var radius: CGFloat = 22.0

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            content
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: radius))
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

struct AutomaticGlassButtonStyleProminentCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .glassEffect(in: Circle())
        } else {
            content
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
        }
    }
}

extension View {
    func glassEffectIfSupported(bordered: Bool = false) -> some View {
        self.modifier(AutomaticGlass(bordered: bordered))
    }

    func glassEffectInteractiveIfSupported() -> some View {
        self.modifier(AutomaticGlassInteractive())
    }

    func glassEffectRegularRoundedIfSupported(radius: CGFloat = 22.0) -> some View {
        self.modifier(AutomaticGlassRounded(radius: radius))
    }

    func buttonStyleGlassProminentIfSupported() -> some View {
        self.modifier(AutomaticGlassButtonStyleProminent())
    }

    func buttonStyleGlassProminentCircularIfSupported() -> some View {
        self.modifier(AutomaticGlassButtonStyleProminentCircle())
    }
}
