import SwiftUI

extension View {
    func circleDestinations() -> some View {
        navigationDestination(for: MockCircle.self) { circle in
            CircleDetailView(circle: circle)
        }
    }
}
