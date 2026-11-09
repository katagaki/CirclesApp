import SwiftUI

struct NaviActiveRoute: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        ScrollView {
            Group {
                if navigator.isFinished {
                    NaviFinishedCard()
                } else if navigator.isTrapped {
                    UnifiedRouteTrappedSection()
                } else if navigator.currentStep == nil {
                    NaviPlanningCard()
                } else {
                    UnifiedRouteStepSection()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20.0)
            .padding(.vertical, 12.0)
        }
    }
}
