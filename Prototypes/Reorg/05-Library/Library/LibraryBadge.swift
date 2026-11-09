import SwiftUI

struct LibraryBadge: View {

    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 8.0)
            .padding(.vertical, 3.0)
            .background(tint, in: .capsule)
    }
}
