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
            content
        }
        .frame(maxWidth: 48.0)
    }
}
