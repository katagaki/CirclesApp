//
//  AdaptiveInvert.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SwiftUI

struct AdaptiveInvert: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    var adaptive: Bool

    func body(content: Content) -> some View {
        if adaptive {
            switch colorScheme {
            case .dark:
                content
                    .colorInvert()
            case .light:
                content
            @unknown default:
                content
            }
        } else {
            content
                .colorInvert()
        }
    }
}

extension View {
    func colorInvert(adaptive: Bool) -> some View {
        self.modifier(AdaptiveInvert(adaptive: adaptive))
    }
}
