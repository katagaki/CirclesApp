import SwiftUI

@main
struct LibraryApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                LibraryRoot()
            }
        }
    }
}
