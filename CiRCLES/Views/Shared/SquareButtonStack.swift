//
//  SquareButtonStack.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/08.
//

import SwiftUI

struct SquareButtonStack<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .trailing, spacing: 12.0) {
            Group {
                content
            }
            .background(Material.regular)
            .clipShape(.rect(cornerRadius: 8.0))
            .shadow(color: .black.opacity(0.2), radius: 4.0, y: 2.0)
        }
        .frame(maxWidth: 48.0)
    }
}
