//
//  OnHandColor.swift
//  OnHand
//
//  Mirrors RADiUS.WebCatalogColor, which the watch target does not link.
//  Keep the values in sync with that enum.
//

import SwiftUI

enum OnHandColor: Int, CaseIterable {
    case uncolored = 0
    case orange = 1
    case pink = 2
    case yellow = 3
    case green = 4
    case cyan = 5
    case purple = 6
    case blue = 7
    case lime = 8
    case red = 9
    case darkOrange = 10
    case darkPurple = 11
    case teal = 12
    case maroon = 13
    case violet = 14
    case gold = 15
    case darkGreen = 16
    case crimson = 17
    case deepPink = 18

    init(value: Int) {
        self = OnHandColor(rawValue: value) ?? .uncolored
    }

    var background: Color {
        switch self {
        case .uncolored: return Color(red: 0.56, green: 0.56, blue: 0.58)
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.29)
        case .pink: return Color(red: 1.0, green: 0.0, blue: 1.0)
        case .yellow: return Color(red: 1.0, green: 0.97, blue: 0.0)
        case .green: return Color(red: 0.0, green: 0.71, blue: 0.29)
        case .cyan: return Color(red: 0.0, green: 0.71, blue: 1.0)
        case .purple: return Color(red: 0.61, green: 0.32, blue: 0.61)
        case .blue: return Color(red: 0.0, green: 0.0, blue: 1.0)
        case .lime: return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .red: return Color(red: 1.0, green: 0.0, blue: 0.0)
        case .darkOrange: return Color(red: 0.91, green: 0.45, blue: 0.13)
        case .darkPurple: return Color(red: 0.48, green: 0.18, blue: 0.56)
        case .teal: return Color(red: 0.17, green: 0.52, blue: 0.53)
        case .maroon: return Color(red: 0.63, green: 0.17, blue: 0.18)
        case .violet: return Color(red: 0.42, green: 0.35, blue: 0.8)
        case .gold: return Color(red: 0.78, green: 0.63, blue: 0.15)
        case .darkGreen: return Color(red: 0.2, green: 0.49, blue: 0.32)
        case .crimson: return Color(red: 0.8, green: 0.16, blue: 0.19)
        case .deepPink: return Color(red: 0.91, green: 0.15, blue: 0.42)
        }
    }

    var foreground: Color {
        switch self {
        case .yellow, .cyan, .lime, .gold: return .black
        default: return .white
        }
    }
}
