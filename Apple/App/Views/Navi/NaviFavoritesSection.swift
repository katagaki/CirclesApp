import SwiftUI

struct NaviFavoritesSection: View {

    let isEnabled: Bool
    let onChoose: (Navigator.Mode) -> Void

    var body: some View {
        Section {
            NaviModeRow(
                title: "Route.Mode.Efficient",
                subtitle: "Route.Mode.Efficient.Description",
                systemImage: "point.topleft.down.to.point.bottomright.curvepath"
            ) {
                onChoose(.efficient)
            }
            NaviModeRow(
                title: "Route.Mode.Prioritized",
                subtitle: "Route.Mode.Prioritized.Description",
                systemImage: "list.number"
            ) {
                onChoose(.prioritized)
            }
        } header: {
            Text("Navi.Favorites")
        }
        .disabled(!isEnabled)
    }
}
