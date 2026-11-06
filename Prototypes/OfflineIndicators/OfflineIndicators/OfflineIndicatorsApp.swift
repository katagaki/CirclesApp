import SwiftUI

@main
struct OfflineIndicatorsApp: App {
    @State private var harness = Harness()

    var body: some Scene {
        WindowGroup {
            ShellView()
                .environment(harness)
        }
    }
}
