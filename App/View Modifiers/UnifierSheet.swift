//
//  UnifierSheet.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/09.
//

import SwiftUI

struct UnifierPanelModifier: ViewModifier {
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        @Bindable var unifier = unifier
        if UIDevice.current.userInterfaceIdiom == .phone {
            content
                .sheet(isPresented: $unifier.isPresenting) {
                    if #available(iOS 26.0, *) {
                        UnifiedPanel()
                            .navigationTransition(.zoom(sourceID: "BottomPanel", in: namespace))
                    } else {
                        UnifiedPanel()
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func unifierPanel(namespace: Namespace.ID) -> some View {
        self.modifier(UnifierPanelModifier(namespace: namespace))
    }
}
