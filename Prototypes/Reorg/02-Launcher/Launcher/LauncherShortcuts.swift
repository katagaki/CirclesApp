import SwiftUI

struct LauncherShortcuts: View {

    var body: some View {
        HStack(spacing: 0.0) {
            LauncherShortcut(feature: .catalog, title: "Circles")
            LauncherShortcut(feature: .favorites, title: "Favorites")
            LauncherShortcut(feature: .buys, title: "Buys")
            LauncherShortcut(feature: .navigation, title: "Route")
            LauncherShortcut(feature: .myComiket, title: "Me")
        }
    }
}
