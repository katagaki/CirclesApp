//
//  AutomaticNavigationTransition.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/31.
//

import SwiftUI

struct AutomaticNavigationTransitionModifier: ViewModifier {

    var id: AnyHashable
    var namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

extension View {
    func automaticNavigationTransition(id: AnyHashable, in namespace: Namespace.ID) -> some View {
        modifier(AutomaticNavigationTransitionModifier(id: id, namespace: namespace))
    }
}
