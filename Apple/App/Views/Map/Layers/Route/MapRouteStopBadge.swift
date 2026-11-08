import SwiftUI

struct MapRouteStopBadge: View {

    enum Phase {
        case done
        case current
        case upcoming
    }

    let number: Int
    let state: Phase
    let size: CGFloat

    var body: some View {
        ZStack {
            switch state {
            case .done:
                Circle()
                    .fill(Color.secondary)
            case .current:
                Circle()
                    .fill(Color.accentColor)
            case .upcoming:
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: size * 0.12)
            }
            if state != .upcoming {
                Circle()
                    .strokeBorder(.white, lineWidth: size * 0.1)
            }
            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .heavy))
            } else {
                Text("\(number)")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(state == .upcoming ? Color.accentColor : .white)
        .frame(width: size, height: size)
        .background {
            Circle()
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.3), radius: size * 0.08, y: size * 0.04)
        }
    }
}
