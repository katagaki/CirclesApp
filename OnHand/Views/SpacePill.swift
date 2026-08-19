//
//  SpacePill.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

struct SpacePill: View {

    let label: String
    let color: OnHandColor
    var fontSize: CGFloat = 20.0
    var isVisited: Bool = false

    var body: some View {
        Text(label)
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .strikethrough(isVisited, pattern: .solid, color: .secondary)
            .foregroundStyle(isVisited ? AnyShapeStyle(.secondary) : AnyShapeStyle(color.foreground))
            .padding(.horizontal, fontSize * 0.32)
            .padding(.vertical, fontSize * 0.08)
            .background(
                Capsule().fill(
                    isVisited ? AnyShapeStyle(.quaternary) : AnyShapeStyle(color.background)
                )
            )
    }
}
