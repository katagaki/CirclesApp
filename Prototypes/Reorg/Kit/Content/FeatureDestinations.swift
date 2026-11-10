import SwiftUI

extension View {
    func featureDestinations() -> some View {
        self
            .circleDestinations()
            .navigationDestination(for: Feature.self) { feature in
                FeatureScreen(feature: feature)
            }
    }
}
