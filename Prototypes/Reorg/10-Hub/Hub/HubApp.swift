import SwiftUI

@main
struct HubApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                HubRoot()
            }
        }
    }
}
