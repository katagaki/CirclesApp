import SwiftUI

struct NaviPlanningCard: View {

    var body: some View {
        HStack(spacing: 12.0) {
            ProgressView()
            Text("Navi.Planning")
                .font(.headline)
            Spacer(minLength: 0.0)
        }
        .padding(.vertical, 8.0)
    }
}
