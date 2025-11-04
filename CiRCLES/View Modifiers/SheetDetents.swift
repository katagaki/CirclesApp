//
//  SheetDetents.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/05.
//

import SwiftUI

struct SheetDetentsModifier: ViewModifier {
    @Binding var selectedDetent: PresentationDetent

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .presentationDetents([.height(150), .height(360), .large], selection: $selectedDetent)
        } else {
            content
                .presentationDetents([.height(120), .height(360), .large], selection: $selectedDetent)
        }
    }
}

extension View {
    func presentationDetentsForUnifiedView(_ selectedDetent: Binding<PresentationDetent>) -> some View {
        self.modifier(SheetDetentsModifier(selectedDetent: selectedDetent))
    }
}
