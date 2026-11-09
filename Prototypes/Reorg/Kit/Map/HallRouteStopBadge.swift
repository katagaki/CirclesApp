import SwiftUI

struct HallRouteStopBadge: View {

    let number: Int
    let isNext: Bool
    let isDone: Bool

    var body: some View {
        Text("\(number)")
            .font(.system(size: isNext ? 13.0 : 10.0, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: isNext ? 26.0 : 18.0, height: isNext ? 26.0 : 18.0)
            .background(isDone ? Color.gray : Color.blue, in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: 2.0))
    }
}
