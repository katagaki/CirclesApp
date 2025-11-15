//
//  AdaptiveNavigationBar.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/13.
//

import SwiftUI

struct AdaptiveNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #unavailable(iOS 26.0) {
            content
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveNavigationBar() -> some View {
        self.modifier(AdaptiveNavigationBarModifier())
    }
}
