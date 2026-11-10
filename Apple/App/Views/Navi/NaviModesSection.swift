import SwiftUI

struct NaviModesSection: View {

    let isEnabled: Bool
    let ownBuysCount: Int
    let sharedBuysCount: Int?
    let onChoose: (Navigator.Mode) -> Void
    let onOwnBuys: () -> Void
    let onSharedBuys: () -> Void

    var body: some View {
        Section {
            NaviFavoriteRows(onChoose: onChoose)
            NaviBuysRows(
                ownCount: ownBuysCount,
                sharedCount: sharedBuysCount,
                onOwn: onOwnBuys,
                onShared: onSharedBuys
            )
        } header: {
            Text("Navi.Modes")
        } footer: {
            if sharedBuysCount != nil {
                Text("Navi.Buys.Shared.Footer")
            }
        }
        .disabled(!isEnabled)
    }
}
