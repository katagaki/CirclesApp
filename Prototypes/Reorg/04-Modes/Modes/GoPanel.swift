import SwiftUI

struct GoPanel: View {

    @Environment(Harness.self) var harness
    @State var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            GoHome()
                .toolbarVisibility(.hidden, for: .navigationBar)
                .featureDestinations()
        }
        .onAppear {
            if let screen = harness.launchScreen, let feature = Feature(rawValue: screen),
               feature == .sharedBuys || feature == .navigation {
                path.append(feature)
            }
        }
    }
}
