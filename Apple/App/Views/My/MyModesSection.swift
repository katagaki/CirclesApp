import SwiftUI

struct MyModesSection: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Unifier.self) var unifier

    @AppStorage(wrappedValue: false, "PrivacyMode.On") var isPrivacyModeOn: Bool

    var body: some View {
        Section {
            if authenticator.isOfflineModeActive || authenticator.canUseOfflineMode {
                Toggle("My.User.OfflineMode", isOn: Binding(
                    get: { authenticator.isOfflineModeActive },
                    set: { isOn in
                        unifier.isMyComiketPresenting = false
                        unifier.hide()
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            if isOn {
                                unifier.isGoingToEnterOfflineMode = true
                            } else {
                                unifier.isGoingToExitOfflineMode = true
                            }
                        }
                    }
                ))
            }
            Toggle("More.PrivacyMode.On", isOn: $isPrivacyModeOn)
        }
    }
}
