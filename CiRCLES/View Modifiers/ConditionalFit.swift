//
//  ConditionalFit.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/07.
//

import SwiftUI

struct ConditionalFit: ViewModifier {
    var shouldScaleToFit: Bool
    var maxSize: CGSize

    func body(content: Content) -> some View {
        ZStack(alignment: .center) {
            if shouldScaleToFit {
                content
                    .scaledToFit()
                    .frame(maxWidth: maxSize.width, maxHeight: maxSize.height, alignment: .center)
            } else {
                content
            }
        }
    }
}

extension View {
    func scaled(_ shouldScaleToFit: Binding<Bool>, to maxSize: CGSize) -> some View {
        self.modifier(ConditionalFit(shouldScaleToFit: shouldScaleToFit.wrappedValue, maxSize: maxSize))
    }
}
