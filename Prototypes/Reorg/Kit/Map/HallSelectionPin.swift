import SwiftUI

struct HallSelectionPin: View {

    let circle: MockCircle

    var body: some View {
        VStack(spacing: 2.0) {
            CircleCut(circle: circle, size: 34.0)
                .overlay(Rectangle().stroke(.white, lineWidth: 2.0))
                .shadow(radius: 3.0)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8.0))
                .foregroundStyle(.white)
                .shadow(radius: 1.0)
        }
        .offset(y: -22.0)
    }
}
