import SwiftUI

struct HarnessCapsule: View {

    @Environment(Harness.self) var harness

    var body: some View {
        @Bindable var harness = harness
        if !harness.isHarnessHidden {
            Menu {
                Toggle("Guest Mode", systemImage: "person.fill.questionmark", isOn: $harness.isGuest)
                Toggle("Offline", systemImage: "wifi.slash", isOn: $harness.isOffline)
                Toggle("Navigating", systemImage: "location.north.line", isOn: $harness.isNavigating)
                Toggle("Shared Buys Active", systemImage: "person.2", isOn: $harness.isSharedBuysActive)
                Divider()
                Button("Hide Harness", systemImage: "eye.slash") { harness.isHarnessHidden = true }
            } label: {
                Text("HARNESS")
                    .font(.system(size: 10.0, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8.0)
                    .padding(.vertical, 4.0)
                    .background(.black, in: .capsule)
            }
        }
    }
}
