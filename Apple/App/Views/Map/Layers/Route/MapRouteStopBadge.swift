import RADiUS
import SwiftUI

struct MapRouteStopBadge: View {

    enum Phase {
        case done
        case current
        case upcoming
    }

    let number: Int
    let state: Phase
    let tint: WebCatalogColor
    let size: CGFloat

    var fill: Color {
        switch state {
        case .done: .gray
        case .current: .red
        case .upcoming: tint == .uncolored ? .accentColor : tint.backgroundColor()
        }
    }

    var glyph: Color {
        state == .upcoming && tint != .uncolored ? tint.foregroundColor() : .white
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
            Circle()
                .strokeBorder(.white, lineWidth: size * 0.1)
            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .heavy))
            } else {
                Text("\(number)")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(glyph)
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: size * 0.08, y: size * 0.04)
    }
}
