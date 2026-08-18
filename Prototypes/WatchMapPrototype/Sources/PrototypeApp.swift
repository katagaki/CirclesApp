import SwiftUI

@main
struct PrototypeApp: App {

    @State private var store = CatalogStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    store.load()
                    HitTestSelfCheck.runIfRequested(store: store)
                }
        }
    }
}
