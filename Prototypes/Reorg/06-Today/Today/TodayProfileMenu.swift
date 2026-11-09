import SwiftUI

struct TodayProfileMenu: View {

    @Environment(Harness.self) var harness
    @Binding var path: NavigationPath

    var body: some View {
        Menu {
            Section(harness.isGuest ? "Guest" : "Justin") {
                Button("My Comiket", systemImage: Feature.myComiket.symbol) { path.append(Feature.myComiket) }
                Button("Event Data", systemImage: Feature.eventData.symbol) { path.append(Feature.eventData) }
                Button("Settings", systemImage: Feature.settings.symbol) { path.append(Feature.settings) }
            }
            if harness.isGuest {
                Button("Sign In with Circle.ms", systemImage: "person.crop.circle.badge.checkmark") { harness.isGuest = false }
            }
        } label: {
            ProfileAvatar(size: 40.0)
        }
    }
}
