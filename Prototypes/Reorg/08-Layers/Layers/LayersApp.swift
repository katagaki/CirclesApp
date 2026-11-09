import SwiftUI

@main
struct LayersApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                LayersRoot()
            }
        }
    }
}
