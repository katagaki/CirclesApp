import SwiftUI

struct NaviActiveRoute: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        ScrollView {
            VStack(spacing: 16.0) {
                Group {
                    if navigator.isTrapped {
                        UnifiedRouteTrappedSection()
                    } else {
                        UnifiedRouteStepSection()
                    }
                }
                .padding(16.0)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 22.0))
            }
            .padding(.horizontal, 20.0)
            .padding(.vertical, 12.0)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
