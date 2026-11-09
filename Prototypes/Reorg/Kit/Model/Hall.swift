import SwiftUI

enum Hall: String, CaseIterable, Identifiable, Hashable {
    case east123, east456, east78, west12, west34, south12

    var id: String { rawValue }

    var name: String {
        switch self {
        case .east123: "East 1–3"
        case .east456: "East 4–6"
        case .east78: "East 7–8"
        case .west12: "West 1–2"
        case .west34: "West 3–4"
        case .south12: "South 1–2"
        }
    }

    var shortName: String {
        switch self {
        case .east123, .east456, .east78: "東"
        case .west12, .west34: "西"
        case .south12: "南"
        }
    }

    var accent: Color {
        switch self {
        case .east123, .east456, .east78: .red
        case .west12, .west34: .blue
        case .south12: .green
        }
    }

    var blocks: [String] {
        switch self {
        case .east123: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]
        case .east456: ["ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ", "シ"]
        case .east78: ["Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ", "Ｆ", "Ｇ", "Ｈ"]
        case .west12: ["あ", "い", "う", "え", "お", "か", "き", "く", "け", "こ"]
        case .west34: ["れ", "ろ", "わ", "を", "ん", "ゃ", "ゅ", "ょ"]
        case .south12: ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
        }
    }
}
