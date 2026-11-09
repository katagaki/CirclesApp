import SwiftUI

@main
struct LauncherApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                LauncherRoot()
            }
        }
    }
}
