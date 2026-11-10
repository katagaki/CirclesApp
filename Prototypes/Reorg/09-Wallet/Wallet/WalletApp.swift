import SwiftUI

@main
struct WalletApp: App {
    var body: some Scene {
        WindowGroup {
            HarnessRoot {
                WalletRoot()
            }
        }
    }
}
