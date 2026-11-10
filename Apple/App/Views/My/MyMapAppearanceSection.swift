import SwiftUI

struct MyMapAppearanceSection: View {

    @AppStorage(wrappedValue: false, "Map.ShowsGenreOverlays") var showGenreOverlay: Bool
    @AppStorage(wrappedValue: true, "Customization.UseDarkModeMaps") var useDarkModeMaps: Bool
    @AppStorage(wrappedValue: true, "Customization.UseHighResolutionMaps") var useHighResolutionMaps: Bool
    @AppStorage(wrappedValue: .popover, "Map.ScrollType") var scrollType: MapAutoScrollType

    var body: some View {
        Section {
            Toggle("More.Customization.Map.ShowsGenreOverlays", isOn: $showGenreOverlay)
            Toggle("More.Customization.Map.UseDarkModeMap", isOn: $useDarkModeMaps)
            Toggle("More.Customization.Map.UseHighDefinitionMap", isOn: $useHighResolutionMaps)
            Toggle("More.Customization.Map.ScrollToSelection", isOn: Binding(
                get: { scrollType == .popover },
                set: { scrollType = $0 ? .popover : .none }
            ))
        } header: {
            Text("My.MapAppearance")
        }
    }
}
