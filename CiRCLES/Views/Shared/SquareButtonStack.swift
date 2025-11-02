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
        HStack(alignment: .center, spacing: 12.0) {
            content
        }
        .frame(maxHeight: 48.0)
    }
}
