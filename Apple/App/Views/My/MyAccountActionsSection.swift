import SwiftUI

private let myPortalURL = "https://myportal.circle.ms/"
private let deleteAccountURL = "https://auth2.circle.ms/Account/WithDraw1"

struct MyAccountActionsSection: View {

    @Environment(\.openURL) var openURL
    @Environment(Unifier.self) var unifier

    var body: some View {
        Section {
            Link(destination: URL(string: myPortalURL)!) {
                HStack {
                    Text("Profile.Edit")
                    Spacer()
                    Image(systemName: "safari")
                        .foregroundStyle(.foreground.opacity(0.5))
                }
            }
            .tint(.primary)
            Button("Shared.Logout") {
                unifier.isMyComiketPresenting = false
                unifier.hide()
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    unifier.isGoingToSignOut = true
                }
            }
            Button("More.DeleteAccount", role: .destructive) {
                openURL(URL(string: deleteAccountURL)!)
            }
        }
    }
}
