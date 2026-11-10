import SwiftUI

struct NaviBuysRows: View {

    let ownCount: Int
    let sharedCount: Int?
    let onOwn: () -> Void
    let onShared: () -> Void

    var body: some View {
        NaviModeRow(
            title: "Navi.Buys.Mine",
            subtitle: ownCount > 0 ? "Navi.Buys.Count.\(ownCount)" : "Navi.Buys.None",
            icon: .ownBuys
        ) {
            onOwn()
        }
        .disabled(ownCount == 0)
        if let sharedCount {
            NaviModeRow(
                title: "Navi.Buys.Shared",
                subtitle: sharedCount > 0 ? "Navi.Buys.Count.\(sharedCount)" : "Navi.Buys.None",
                icon: .sharedBuys
            ) {
                onShared()
            }
            .disabled(sharedCount == 0)
        }
    }
}
