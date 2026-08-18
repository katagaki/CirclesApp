import SwiftUI
import WidgetKit

struct NextStopEntry: TimelineEntry {
    let date: Date
    let spaceLabel: String
    let hallName: String
    let circleName: String
    let color: Color
    let position: Int
    let total: Int
    let buyCount: Int

    static let placeholder = NextStopEntry(
        date: .now,
        spaceLabel: "あ02a",
        hallName: "東123",
        circleName: "デモ用サークル0007",
        color: FavoriteColor.orange.color,
        position: 3,
        total: 20,
        buyCount: 2
    )
}
