//
//  AdaptiveGlass.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/02.
//

import SwiftUI

// swiftlint:disable force_cast
struct AdaptiveGlass: ViewModifier {
    let style: AdaptiveGlassStyle
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(style.style as! Glass, in: .rect(cornerRadius: cornerRadius ?? 20.0))
        } else {
            switch style {
            case .regular:
                content
                    .background(style.style as! Material)
                    .cornerRadius(cornerRadius ?? 16.0)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius ?? 16.0)
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    }
            case .coloredInteractive(let color):
                content
                    .background(style.style as! Material)
                    .background(color)
                    .cornerRadius(cornerRadius ?? 16.0)
            }
        }
    }
}
// swiftlint:enable force_cast

enum AdaptiveGlassStyle {
    case regular
    case coloredInteractive(color: Color)

    var style: Any {
        if #available(iOS 26.0, *) {
            switch self {
            case .regular:
                return Glass.regular
            case .coloredInteractive(let color):
                return Glass.regular.interactive().tint(color)
            }
        } else {
            return Material.ultraThin
        }
    }
}

extension View {
    func adaptiveGlass(_ style: AdaptiveGlassStyle, cornerRadius: CGFloat? = nil) -> some View {
        modifier(AdaptiveGlass(style: style, cornerRadius: cornerRadius))
    }
}
