import SwiftUI

struct SpotlightToggle: Identifiable {
    let id: String
    let title: String
    let section: String
    let symbol: String
    var keywords: [String] = []
    let isOn: Binding<Bool>
}
