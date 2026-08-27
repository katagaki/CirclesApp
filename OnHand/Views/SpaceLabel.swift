//
//  SpaceLabel.swift
//  OnHand
//
//  Created by シン・ジャスティン on 2026/08/19.
//

import SwiftUI

struct SpaceLabel: View {

    let label: String
    let color: OnHandColor
    var fontSize: CGFloat = 20.0
    var isVisited: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: fontSize * 0.2) {
            Text(label)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(color.background.opacity(isVisited ? 0.35 : 1.0))

            if isVisited {
                VisitedCheckmark(fontSize: fontSize)
            }
        }
    }
}

struct VisitedCheckmark: View {

    let fontSize: CGFloat

    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: fontSize * 0.8, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.accentColor)
            .allowsHitTesting(false)
    }
}
