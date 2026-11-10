import SwiftUI

struct SpotlightResults: View {

    @Environment(Harness.self) var harness
    @Environment(SpotlightSettings.self) var settings
    @Binding var path: NavigationPath

    var body: some View {
        let index = SpotlightIndex(harness: harness, settings: settings, query: harness.searchText)
        let screens = index.screens
        let actions = index.actions
        let toggles = index.toggles
        let circles = index.circles
        if !screens.isEmpty {
            Section("Screens") {
                ForEach(screens) { feature in
                    NavigationLink(value: feature) {
                        SpotlightRowLabel(title: feature.title, symbol: feature.symbol, tint: feature.tint)
                    }
                }
            }
        }
        if !actions.isEmpty {
            Section("Actions") {
                ForEach(actions) { action in
                    SpotlightActionRow(action: action, path: $path)
                }
            }
        }
        if !toggles.isEmpty {
            Section("Settings") {
                ForEach(toggles) { toggle in
                    SpotlightToggleRow(toggle: toggle)
                }
            }
        }
        if !circles.isEmpty {
            Section("Circles · \(circles.count)") {
                ForEach(circles.prefix(12)) { circle in
                    NavigationLink(value: circle) {
                        CircleRow(circle: circle)
                    }
                }
            }
        }
        if screens.isEmpty && actions.isEmpty && toggles.isEmpty && circles.isEmpty {
            ContentUnavailableView.search(text: harness.searchText)
                .listRowBackground(Color.clear)
        }
    }
}
