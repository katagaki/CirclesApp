//
//  SquareButton.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/08.
//

import SwiftUI

struct SquareButton<Content: View>: View {
    var action: () -> Void
    @ViewBuilder let label: Content

    var body: some View {
        Button {
            action()
        } label: {
            label
        }
        .frame(width: 48.0, height: 48.0, alignment: .center)
        .contentShape(.rect)
    }
}
