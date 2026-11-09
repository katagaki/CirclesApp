import SwiftUI

struct MyModesSection: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Unifier.self) var unifier

    @State var isConfirmingEnterOfflineMode: Bool = false
    @State var isConfirmingExitOfflineMode: Bool = false

    @AppStorage(wrappedValue: false, "PrivacyMode.On") var isPrivacyModeOn: Bool

    var body: some View {
        Section {
            if authenticator.isOfflineModeActive || authenticator.canUseOfflineMode {
                Toggle("My.User.OfflineMode", isOn: Binding(
                    get: { authenticator.isOfflineModeActive },
                    set: { isOn in
                        if isOn {
                            isConfirmingEnterOfflineMode = true
                        } else {
                            isConfirmingExitOfflineMode = true
                        }
                    }
                ))
            }
            Toggle("More.PrivacyMode.On", isOn: $isPrivacyModeOn)
        }
        .alert("Alerts.OfflineMode.Enter.Title", isPresented: $isConfirmingEnterOfflineMode) {
            Button("Shared.Cancel", role: .cancel) { }
            Button("More.EnterOfflineMode") {
                authenticator.enterOfflineMode()
            }
        } message: {
            Text("Alerts.OfflineMode.Enter.Message")
        }
        .alert("Alerts.OfflineMode.Exit.Title", isPresented: $isConfirmingExitOfflineMode) {
            Button("Shared.Cancel", role: .cancel) { }
            Button("More.ExitOfflineMode") {
                unifier.isMyComiketPresenting = false
                unifier.close()
                Task {
                    try? await Task.sleep(for: .seconds(0.6))
                    authenticator.exitOfflineMode()
                }
            }
        } message: {
            Text("Alerts.OfflineMode.Exit.Message")
        }
    }
}
