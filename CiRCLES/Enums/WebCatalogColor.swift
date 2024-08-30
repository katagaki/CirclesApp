//
//  WebCatalogColor.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

enum WebCatalogColor: Int, CaseIterable, Codable {
    case orange = 1
    case pink = 2
    case yellow = 3
    case green = 4
    case cyan = 5
    case purple = 6
    case blue = 7
    case lime = 8
    case red = 9

    func swiftUIColor() -> Color {
        switch self {
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.29)
        case .pink: return Color(red: 1.0, green: 0.0, blue: 1.0)
        case .yellow: return Color(red: 1.0, green: 0.97, blue: 0.0)
        case .green: return Color(red: 0.0, green: 0.71, blue: 0.29)
        case .cyan: return Color(red: 0.0, green: 0.71, blue: 1.0)
        case .purple: return Color(red: 0.61, green: 0.32, blue: 0.61)
        case .blue: return Color(red: 0.0, green: 0.0, blue: 1.0)
        case .lime: return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .red: return Color(red: 1.0, green: 0.0, blue: 0.0)
        }
    }
}
