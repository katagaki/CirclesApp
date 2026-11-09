import SwiftUI

struct ProfileAvatar: View {

    @Environment(Harness.self) var harness
    var size: CGFloat = 32.0

    var body: some View {
        Image(systemName: harness.isGuest ? "person.fill.questionmark" : "figure.hiking")
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background((harness.isGuest ? Color.gray : Color.teal).gradient, in: .circle)
    }
}
