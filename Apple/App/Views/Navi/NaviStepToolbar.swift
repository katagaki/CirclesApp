import AXiS
import SwiftUI

/// Detour, back and forward keep the same place on every step, so they can be tapped
/// without looking; they only grey out when a step has nothing for them to do.
struct NaviStepToolbar: ToolbarContent {

    @Environment(Database.self) var database
    @Environment(Navigator.self) var navigator

    var isOnStep: Bool {
        navigator.currentStep != nil && !navigator.isFinished && !navigator.isTrapped
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button("Route.Blocked") {
                navigator.reportBlocked(database: database)
            }
            .disabled(!isOnStep || !navigator.canReportBlocked)
        }
        ToolbarSpacer(.fixed, placement: .bottomBar)
        ToolbarItemGroup(placement: .bottomBar) {
            Button("Route.Previous", systemImage: "chevron.backward") {
                navigator.previous()
            }
            .disabled(!navigator.isFinished && (!isOnStep || navigator.stepIndex == 0))
            Button(
                navigator.currentStep?.isArrival == true ? "Route.Skip" : "Route.Next",
                systemImage: "chevron.forward"
            ) {
                navigator.skip()
            }
            .disabled(!isOnStep)
        }
    }
}
