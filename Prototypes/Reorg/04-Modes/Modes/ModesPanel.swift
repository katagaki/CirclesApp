import SwiftUI

struct ModesPanel: View {

    let mode: AppMode

    var body: some View {
        switch mode {
        case .plan: PlanPanel()
        case .go: GoPanel()
        }
    }
}
