//
//  OnHandHallColor.swift
//  OnHand
//
//  Mirrors AXiS.ComiketHall, which the watch target does not link.
//  Keep the cases in sync with that enum.
//

import SwiftUI

enum OnHandHall: String, CaseIterable {
    case east123 = "E123"
    case east456 = "E456"
    case east7 = "E7"
    case east78 = "E78"
    case west12 = "W12"
    case west34 = "W34"
    case south12 = "S12"
    case south34 = "S34"

    var color: Color {
        switch self {
        case .east123, .east456, .east7, .east78: return Color(red: 0.90, green: 0.25, blue: 0.21)
        case .west12, .west34: return Color(red: 0.20, green: 0.51, blue: 0.93)
        case .south12, .south34: return Color(red: 0.18, green: 0.68, blue: 0.40)
        }
    }

    static func color(for filename: String) -> Color {
        OnHandHall(rawValue: filename)?.color ?? Color.secondary
    }
}

struct HallBadge: View {

    let name: String
    let filename: String
    var fontSize: CGFloat = 14.0

    var color: Color {
        OnHandHall.color(for: filename)
    }

    var body: some View {
        Text(name)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, fontSize * 0.42)
            .padding(.vertical, fontSize * 0.16)
            .background(Capsule().fill(color))
    }
}
