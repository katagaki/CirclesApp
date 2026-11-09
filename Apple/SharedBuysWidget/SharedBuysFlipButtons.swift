import AppIntents
import ORBiT
import SwiftUI

struct SharedBuysFlipButtons: View {

    var body: some View {
        HStack(spacing: 6.0) {
            button(isForward: false, systemName: "chevron.backward")
            button(isForward: true, systemName: "chevron.forward")
        }
    }

    func button(isForward: Bool, systemName: String) -> some View {
        Button(intent: SharedBuysFlipIntent(isForward: isForward)) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.bold))
                .frame(width: 36.0, height: 36.0)
        }
        .buttonStyle(.plain)
        .background(.quaternary, in: .circle)
    }
}
