//
//  WebCatalogColor.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

public enum WebCatalogColor: Int, CaseIterable, Codable, Sendable {
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

    public static var assignable: [WebCatalogColor] {
        allCases.filter({ $0 != .uncolored })
    }

    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(Int.self)
        self = WebCatalogColor(rawValue: rawValue) ?? .uncolored
    }

    public func backgroundColor() -> Color {
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

    public func foregroundColor() -> Color {
        switch self {
        case .uncolored, .orange, .pink, .green, .purple, .blue, .red,
             .darkOrange, .darkPurple, .teal, .maroon, .violet, .darkGreen, .crimson, .deepPink:
            return .white
        case .yellow, .cyan, .lime, .gold:
            return .black
        }
    }

    public func name() -> String {
        switch self {
        case .uncolored: return String(localized: "Color.None")
        case .orange: return String(localized: "Color.Orange")
        case .pink: return String(localized: "Color.Pink")
        case .yellow: return String(localized: "Color.Yellow")
        case .green: return String(localized: "Color.Green")
        case .cyan: return String(localized: "Color.LightBlue")
        case .purple: return String(localized: "Color.Purple")
        case .blue: return String(localized: "Color.Blue")
        case .lime: return String(localized: "Color.LightGreen")
        case .red: return String(localized: "Color.Red")
        case .darkOrange: return String(localized: "Color.DarkOrange")
        case .darkPurple: return String(localized: "Color.DarkPurple")
        case .teal: return String(localized: "Color.Teal")
        case .maroon: return String(localized: "Color.Maroon")
        case .violet: return String(localized: "Color.Violet")
        case .gold: return String(localized: "Color.Gold")
        case .darkGreen: return String(localized: "Color.DarkGreen")
        case .crimson: return String(localized: "Color.Crimson")
        case .deepPink: return String(localized: "Color.DeepPink")
        }
    }
}
