import SwiftUI

struct NaviBuysSection: View {

    let isEnabled: Bool
    let ownCount: Int
    let sharedCount: Int?
    let onOwn: () -> Void
    let onShared: () -> Void

    var body: some View {
        Section {
            NaviModeRow(
                title: "Navi.Buys.Mine",
                subtitle: ownCount > 0 ? "Navi.Buys.Count.\(ownCount)" : "Navi.Buys.None",
                systemImage: "bag"
            ) {
                onOwn()
            }
            .disabled(ownCount == 0)
            if let sharedCount {
                NaviModeRow(
                    title: "Navi.Buys.Shared",
                    subtitle: sharedCount > 0 ? "Navi.Buys.Count.\(sharedCount)" : "Navi.Buys.None",
                    systemImage: "person.2"
                ) {
                    onShared()
                }
                .disabled(sharedCount == 0)
            }
        } header: {
            Text("Navi.Buys")
        } footer: {
            if sharedCount != nil {
                Text("Navi.Buys.Shared.Footer")
            }
        }
        .disabled(!isEnabled)
    }
}
