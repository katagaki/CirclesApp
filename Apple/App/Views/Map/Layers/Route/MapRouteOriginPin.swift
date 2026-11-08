import SwiftUI

struct MapRouteOriginPin: View {

    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.25))
                .frame(width: size * 1.8, height: size * 1.8)
            Circle()
                .fill(Color.accentColor)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: size * 0.08)
            Circle()
                .strokeBorder(.white, lineWidth: size * 0.15)
                .frame(width: size, height: size)
            Image(systemName: "figure.walk")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
