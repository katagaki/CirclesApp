import SwiftUI

struct SpotlightAction: Identifiable {
    let id: String
    let title: String
    var subtitle: String?
    let symbol: String
    let tint: Color
    var keywords: [String] = []
    var destination: Feature?
    let perform: () -> Void
}
