import SwiftUI

struct ToolbeltMeView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            Section {
                NavigationLink(value: Feature.myComiket) {
                    ProfileHeader()
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
                NavigationLink(value: Feature.myComiket) {
                    Label("My Comiket", systemImage: Feature.myComiket.symbol)
                }
                NavigationLink(value: Feature.eventData) {
                    LabeledContent {
                        Text(harness.isOffline ? "Offline · on device" : "Downloaded")
                    } label: {
                        Label("Event Data", systemImage: Feature.eventData.symbol)
                    }
                }
                NavigationLink(value: Feature.settings) {
                    Label("Settings", systemImage: Feature.settings.symbol)
                }
            }
        }
    }
}
