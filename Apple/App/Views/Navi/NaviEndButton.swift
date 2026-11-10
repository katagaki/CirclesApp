import SwiftUI

struct NaviEndButton: View {

    @Environment(Navigator.self) var navigator

    @State var isConfirmingEnd: Bool = false

    var body: some View {
        Button(role: .destructive) {
            isConfirmingEnd = true
        } label: {
            Text("Route.End.Short")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .buttonStyle(.glassProminent)
        .tint(.red)
        .confirmationDialog("Route.End.Confirm", isPresented: $isConfirmingEnd, titleVisibility: .visible) {
            Button("Route.End", role: .destructive) {
                navigator.end()
            }
        }
    }
}
