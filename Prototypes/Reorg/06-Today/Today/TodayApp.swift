import SwiftUI

@main
struct TodayApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                TodayRoot()
            }
        }
    }
}
