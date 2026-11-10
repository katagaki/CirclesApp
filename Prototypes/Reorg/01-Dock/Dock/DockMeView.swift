import SwiftUI

struct DockMeView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section {
                NavigationLink(value: Feature.myComiket) {
                    ProfileHeader()
                }
            }
            Section("At the Event") {
                NavigationLink(value: Feature.navigation) {
                    Label("Route", systemImage: Feature.navigation.symbol)
                }
                NavigationLink(value: Feature.sharedBuys) {
                    Label("Shared Buys", systemImage: Feature.sharedBuys.symbol)
                }
            }
            Section {
                NavigationLink(value: Feature.eventData) {
                    Label("Event Data", systemImage: Feature.eventData.symbol)
                }
                NavigationLink(value: Feature.settings) {
                    Label("Settings", systemImage: Feature.settings.symbol)
                }
            }
        }
    }
}
