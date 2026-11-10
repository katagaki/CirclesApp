import SwiftUI

enum AppMode: String, CaseIterable, Identifiable {
    case plan, go

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plan: "Plan"
        case .go: "Go"
        }
    }

    var symbol: String {
        switch self {
        case .plan: "list.bullet.clipboard"
        case .go: "figure.walk"
        }
    }

    var tint: Color {
        switch self {
        case .plan: .indigo
        case .go: .green
        }
    }

    var smallDetent: PresentationDetent {
        switch self {
        case .plan: .height(150)
        case .go: .height(210)
        }
    }

    var defaultDetent: PresentationDetent {
        switch self {
        case .plan: .medium
        case .go: smallDetent
        }
    }

    var detents: Set<PresentationDetent> {
        [smallDetent, .medium, .large]
    }
}
