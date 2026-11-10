import SwiftUI

@main
struct DockApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                DockRoot()
            }
        }
    }
}
