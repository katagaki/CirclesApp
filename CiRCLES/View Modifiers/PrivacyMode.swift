//
//  PrivacyMode.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

struct PrivacyModeModifier: ViewModifier {
    @AppStorage(wrappedValue: false, "PrivacyMode.On") var isPrivacyModeOn: Bool

    func body(content: Content) -> some View {
        if isPrivacyModeOn {
            content
                .blur(radius: 10.0)
                .clipped()
        } else {
            content
        }
    }
}

extension View {
    func usesPrivacyMode() -> some View {
        self.modifier(PrivacyModeModifier())
    }
}
