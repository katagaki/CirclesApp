import SwiftUI

@main
struct OnHandApp: App {

    @State var store = OnHandStore()

    var body: some Scene {
        WindowGroup {
            OnHandRootView()
                .environment(store)
                .task {
                    store.activate()
                }
        }
    }
}
