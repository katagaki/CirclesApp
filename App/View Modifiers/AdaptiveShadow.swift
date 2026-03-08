//
//  AdaptiveShadow.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/08/19.
//

import SwiftUI

struct AdaptiveShadow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        switch colorScheme {
        case .dark:
            content
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 10.0,
                    x: 0.0,
                    y: 1.0
                )
        case .light:
            content
        @unknown default:
            content
        }
    }
}

extension View {
    func adaptiveShadow() -> some View {
        self.modifier(AdaptiveShadow())
    }
}
