import SwiftUI

struct GoReadinessPill: View {

    var body: some View {
        HStack(spacing: 6.0) {
            Image(systemName: "checkmark.icloud")
            Text("Ready offline").font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.green)
        .padding(.horizontal, 12.0)
        .frame(height: 36.0)
        .glassEffect(.regular, in: .capsule)
    }
}
