import SwiftUI

struct LayerMarker: View {

    let symbol: String
    let tint: Color
    var label: String?

    var body: some View {
        HStack(spacing: 2.0) {
            Image(systemName: symbol)
                .font(.system(size: 9.0, weight: .bold))
            if let label {
                Text(label).font(.system(size: 10.0, weight: .bold).monospacedDigit())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, label == nil ? 0.0 : 5.0)
        .frame(minWidth: 18.0, minHeight: 18.0)
        .background(tint, in: .capsule)
        .overlay(Capsule().stroke(.white, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.2), radius: 2.0, y: 1.0)
    }
}
