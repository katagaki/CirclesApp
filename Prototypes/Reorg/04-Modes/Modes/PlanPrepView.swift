import SwiftUI

struct PlanPrepView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section("Your Comiket") {
                NavigationLink(value: Feature.myComiket) {
                    ProfileHeader()
                }
                LabeledContent("Going", value: harness.isGuest ? "Sign in to plan" : "Day 1 · Sat 27 Dec")
            }
            Section {
                NavigationLink(value: Feature.eventData) {
                    LabeledContent {
                        Text(harness.isOffline ? "Offline" : "Up to date")
                    } label: {
                        Label("Event Data", systemImage: Feature.eventData.symbol)
                    }
                }
                Label("Circle cuts downloaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } header: {
                Text("Download Before You Go")
            } footer: {
                Text("Catalog, circle cuts and maps are stored on this device so Go mode works without signal.")
            }
            Section("Get Ready") {
                NavigationLink(value: Feature.navigation) {
                    Label("Preview Route · \(harness.routeStops.count) stops", systemImage: Feature.navigation.symbol)
                }
                SharedBuysEntryRow()
                NavigationLink(value: Feature.settings) {
                    Label("Settings", systemImage: Feature.settings.symbol)
                }
            }
        }
    }
}
