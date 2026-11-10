import SwiftUI

struct MockCircle: Identifiable, Hashable {
    let id: Int
    let name: String
    let author: String
    let genre: String
    let hall: Hall
    let block: String
    let space: Int
    let half: String
    let day: Int
    let hue: Double
    let blockIndex: Int
    let slotIndex: Int

    var spaceName: String { "\(hall.shortName)\(block)-\(String(format: "%02d", space))\(half)" }
    var dayName: String { "Day \(day)" }
    var cutColor: Color { Color(hue: hue, saturation: 0.45, brightness: 0.9) }
    var initial: String { String(name.prefix(1)) }
}
