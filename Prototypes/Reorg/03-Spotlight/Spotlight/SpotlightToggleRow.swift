import SwiftUI

struct SpotlightToggleRow: View {

    let toggle: SpotlightToggle

    var body: some View {
        Toggle(isOn: toggle.isOn) {
            SpotlightRowLabel(title: toggle.title, subtitle: "Settings › \(toggle.section)", symbol: toggle.symbol, tint: .gray)
        }
    }
}
