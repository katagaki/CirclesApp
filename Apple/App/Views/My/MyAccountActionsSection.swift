import SwiftUI
import AXiS

private let myPortalURL = "https://myportal.circle.ms/"
private let deleteAccountURL = "https://auth2.circle.ms/Account/WithDraw1"

struct MyAccountActionsSection: View {

    @Environment(\.openURL) var openURL
    @Environment(Authenticator.self) var authenticator
    @Environment(Database.self) var database
    @Environment(ImageCache.self) var imageCache
    @Environment(Unifier.self) var unifier

    @State var isConfirmingLogout: Bool = false

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
                isConfirmingLogout = true
            }
            Button("More.DeleteAccount", role: .destructive) {
                openURL(URL(string: deleteAccountURL)!)
            }
        }
        .alert("Alerts.Logout.Title", isPresented: $isConfirmingLogout) {
            Button("Shared.Cancel", role: .cancel) { }
            Button("Shared.Logout", role: .destructive) {
                unifier.isMyComiketPresenting = false
                unifier.close()
                Task {
                    try? await Task.sleep(for: .seconds(0.6))
                    logout()
                }
            }
        } message: {
            Text("Alerts.Logout.Message")
        }
    }

    func logout() {
        database.delete()
        imageCache.clear()
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        imageCache.clear()
        database.reset()
        unifier.close()
        authenticator.resetAuthentication()
    }
}
