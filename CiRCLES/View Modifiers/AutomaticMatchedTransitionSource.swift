//
//  AutomaticMatchedTransitionSource.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/31.
//

import SwiftUI

struct AutomaticMatchedTransitionSourceModifier: ViewModifier {

    var id: AnyHashable
    var namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

extension View {
    func automaticMatchedTransitionSource(id: AnyHashable, in namespace: Namespace.ID) -> some View {
        modifier(AutomaticMatchedTransitionSourceModifier(id: id, namespace: namespace))
    }
}
