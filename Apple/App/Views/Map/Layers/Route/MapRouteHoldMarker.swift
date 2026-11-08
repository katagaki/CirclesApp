import SwiftUI

struct MapRouteHoldMarker: View {

    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(0.15))
                .frame(width: size * 1.8, height: size * 1.8)
            Circle()
                .fill(.background)
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(Color.primary, lineWidth: size * 0.12)
                .frame(width: size, height: size)
            Image(systemName: "questionmark")
                .font(.system(size: size * 0.45, weight: .bold))
        }
        .shadow(color: .black.opacity(0.25), radius: size * 0.08)
    }
}
