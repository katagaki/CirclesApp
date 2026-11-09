import SwiftUI

struct SharedMember: Identifiable, Hashable {
    let id: String
    let name: String
    let hue: Double
    let location: String
    let progress: Double

    var color: Color { Color(hue: hue, saturation: 0.6, brightness: 0.85) }
    var initial: String { String(name.prefix(1)) }
}
