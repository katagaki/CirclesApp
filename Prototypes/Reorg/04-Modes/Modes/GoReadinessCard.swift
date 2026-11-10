import SwiftUI

struct GoReadinessCard: View {

    @Environment(Harness.self) var harness

    var body: some View {
        @Bindable var harness = harness
        GoCard {
            GoReadinessRow(title: "Catalog and circle cuts", detail: "C107 · 1.6 GB", isReady: true)
            GoReadinessRow(title: "Hall maps", detail: "All 6 halls", isReady: true)
            GoReadinessRow(title: "Shared Buys sync",
                           detail: harness.isOffline ? "Waiting for signal" : "Live",
                           isReady: !harness.isOffline)
            Toggle("Offline Mode", systemImage: "wifi.slash", isOn: $harness.isOffline)
            NavigationLink(value: Feature.eventData) {
                Text("Manage Event Data").font(.subheadline)
            }
        }
    }
}
