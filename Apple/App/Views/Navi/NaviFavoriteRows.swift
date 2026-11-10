import SwiftUI

struct NaviFavoriteRows: View {

    let onChoose: (Navigator.Mode) -> Void

    var body: some View {
        NaviModeRow(
            title: "Route.Mode.Efficient",
            subtitle: "Route.Mode.Efficient.Description",
            icon: .automatic
        ) {
            onChoose(.efficient)
        }
        NaviModeRow(
            title: "Route.Mode.Prioritized",
            subtitle: "Route.Mode.Prioritized.Description",
            icon: .colors
        ) {
            onChoose(.prioritized)
        }
    }
}
