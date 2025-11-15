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
                .overlay {
                    Canvas { context, size in
                        let strokeWidth = 0.03 * size.width
                        let checkmarkSquareSize = 0.23 * size.width
                        let borderPath = Path(
                            CGRect(
                                x: strokeWidth / 2,
                                y: strokeWidth / 2,
                                width: size.width - strokeWidth,
                                height: size.height - strokeWidth
                            )
                        )
                        let checkmarkSquareBorderPath = Path(
                            CGRect(
                                x: strokeWidth / 2,
                                y: strokeWidth / 2,
                                width: checkmarkSquareSize + strokeWidth,
                                height: checkmarkSquareSize + strokeWidth
                            )
                        )
                        context.stroke(borderPath, with: .color(.black), lineWidth: strokeWidth)
                        context.stroke(checkmarkSquareBorderPath, with: .color(.black), lineWidth: strokeWidth)
                    }
                }
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
