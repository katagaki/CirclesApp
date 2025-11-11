//
//  VisitMode.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

struct VisitModeModifier: ViewModifier {
    @Binding var isVisitModeOn: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                if isVisitModeOn {
                    content
                        .presentationBackground(Color.accentColor.opacity(0.2))
                } else {
                    content
                }
            } else {
                content
                    .background(isVisitModeOn ? Color.accentColor.opacity(0.2) : Color.clear)
            }
        } else {
            content
                .overlay {
                    if isVisitModeOn {
                        GradientBorder()
                            .ignoresSafeArea(edges: .all)
                    }
                }
        }
    }
}

extension View {
    func visitModeStyle(_ isVisitModeOn: Binding<Bool>) -> some View {
        self.modifier(VisitModeModifier(isVisitModeOn: isVisitModeOn))
    }
}
