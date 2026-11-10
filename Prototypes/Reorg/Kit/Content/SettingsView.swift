import SwiftUI

struct SettingsView: View {

    @Environment(Harness.self) var harness
    @State var genreOverlays = false
    @State var darkMaps = true
    @State var hdMaps = true
    @State var showSpace = true
    @State var showDay = false
    @State var doubleTap = true
    @State var privacy = false

    var body: some View {
        @Bindable var harness = harness
        List {
            Section("Event Data") {
                NavigationLink(value: Feature.eventData) {
                    Label("Downloaded Data", systemImage: "externaldrive")
                }
                Label("Backup to iCloud", systemImage: "icloud")
            }
            Section("Map") {
                Toggle("Genre Overlays", systemImage: "theatermasks", isOn: $genreOverlays)
                Toggle("Dark Maps", systemImage: "moon", isOn: $darkMaps)
                Toggle("High Resolution", systemImage: "square.resize.up", isOn: $hdMaps)
            }
            Section("Circles") {
                Toggle("Show Hall and Block", systemImage: "table.furniture", isOn: $showSpace)
                Toggle("Show Day", systemImage: "calendar", isOn: $showDay)
                Toggle("Double Tap to Visit", systemImage: "hand.tap", isOn: $doubleTap)
            }
            Section("Privacy") {
                Toggle("Privacy Mode", systemImage: "eye.slash", isOn: $privacy)
            }
            Section("Useful Links") {
                Label("Web Catalog", systemImage: "safari")
                Label("Getting to Tokyo Big Sight", systemImage: "tram")
                Label("Big Sight Floor Map", systemImage: "map")
            }
            Section("Account") {
                Toggle("Offline Mode", systemImage: "wifi.slash", isOn: $harness.isOffline)
                if harness.isGuest {
                    Button("Sign In") { harness.isGuest = false }
                } else {
                    Button("Sign Out") {}
                    Button("Delete Account", role: .destructive) {}
                }
            }
        }
        .navigationTitle("Settings")
    }
}
