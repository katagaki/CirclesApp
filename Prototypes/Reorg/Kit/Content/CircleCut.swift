import SwiftUI

struct CircleCut: View {

    let circle: MockCircle
    var size: CGFloat = 56.0

    var body: some View {
        ZStack {
            Rectangle().fill(circle.cutColor.gradient)
            Text(circle.initial)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.15), radius: 1.0)
        }
        .frame(width: size, height: size * 1.42)
        .overlay(Rectangle().stroke(.black.opacity(0.08), lineWidth: 0.5))
    }
}
