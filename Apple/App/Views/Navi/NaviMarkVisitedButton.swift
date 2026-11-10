import SwiftUI

struct NaviMarkVisitedButton: View {

    @Environment(Navigator.self) var navigator

    var body: some View {
        Button {
            navigator.markVisitedAndContinue()
        } label: {
            Label("Route.MarkVisited", systemImage: "checkmark")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .fixedSize()
                .frame(height: 26.0)
                .padding(.horizontal, 4.0)
        }
        .buttonStyle(.glassProminent)
        .tint(.accentColor)
    }
}
