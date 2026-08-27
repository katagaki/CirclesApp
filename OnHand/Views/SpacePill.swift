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
            .foregroundStyle(isVisited ? AnyShapeStyle(.secondary) : AnyShapeStyle(color.foreground))
            .padding(.horizontal, fontSize * 0.32)
            .padding(.vertical, fontSize * 0.08)
            .background(
                Capsule().fill(
                    isVisited ? AnyShapeStyle(.quaternary) : AnyShapeStyle(color.background)
                )
            )
            .overlay(alignment: .center) {
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
            .font(.system(size: fontSize * 1.6, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.accentColor)
            .rotationEffect(.degrees(-13.0))
            .offset(x: fontSize * 0.28, y: -fontSize * 0.22)
            .shadow(color: .black.opacity(0.5), radius: 2.0, y: 1.0)
            .allowsHitTesting(false)
    }
}
