import SwiftUI

struct HubMeView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        @Bindable var harness = harness
        List {
            Section {
                NavigationLink(value: Feature.myComiket) {
                    ProfileHeader()
                }
            } footer: {
                if !harness.isGuest {
                    Text("Participation, reminders and your Circle.ms profile")
                }
            }
            if harness.isGuest {
                Section {
                    GuestBanner()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            }
            Section {
                Toggle("Offline Mode", systemImage: "wifi.slash", isOn: $harness.isOffline)
            } footer: {
                Text(harness.isOffline ? "Using downloaded event data. Favorites sync when you're back online." : "Turn on to stop using the network at the venue.")
            }
            Section("Event Data") {
                NavigationLink(value: Feature.eventData) {
                    Label("Downloaded Data", systemImage: "externaldrive")
                }
                Label("Backup to iCloud", systemImage: "icloud")
            }
            Section("App") {
                NavigationLink(value: Feature.settings) {
                    Label("Map & Circle Display", systemImage: "paintbrush")
                }
                Label("Web Catalog", systemImage: "safari")
                Label("Getting to Tokyo Big Sight", systemImage: "tram")
            }
            Section("Account") {
                if harness.isGuest {
                    Button("Sign In") { harness.isGuest = false }
                } else {
                    Button("Sign Out") {}
                }
            }
        }
        .navigationTitle("Me")
    }
}
