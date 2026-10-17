import ORBiT
import SwiftUI

struct UnifiedViewPicker: View {

    @Environment(Events.self) var planner
    @Environment(Unifier.self) var unifier
    @Environment(SharedBuysSession.self) var sharedBuys

    var body: some View {
        @Bindable var unifier = unifier
        Picker(selection: $unifier.current) {
            Text("ViewTitle.Circles")
                .tag(UnifiedPath.circles)
            if planner.isActiveEventLatest {
                Text("ViewTitle.Favorites")
                    .tag(UnifiedPath.favorites)
            }
            if sharedBuys.isFeatureEnabled {
                Text("ViewTitle.Buys")
                    .tag(UnifiedPath.buys)
            }
        } label: {
            // Label intentionally left empty; the picker uses segmented style.
        }
            .id("Unifier.Picker")
            .pickerStyle(.segmented)
    }
}
